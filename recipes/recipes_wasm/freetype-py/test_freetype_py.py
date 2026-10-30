import base64
import ctypes
import os
import tempfile
from ctypes import POINTER, Structure, byref, c_long, c_ushort, cast

import freetype
import freetype.raw as raw
import pytest

# fonts from the freetype-py sdist (examples/), embedded by
# make_test_fontdata.py; written to files here
from test_fontdata import FONTS

_FONT_DIR = tempfile.mkdtemp()


def _font_file(name):
    path = os.path.join(_FONT_DIR, name)
    with open(path, "wb") as f:
        f.write(base64.b64decode(FONTS[name]))
    return path


VERA = _font_file("Vera.ttf")
VERA_MONO = _font_file("VeraMono.ttf")
SOURCE_SANS_VF = _font_file("SourceSansVariable-Roman.otf")

# C long: 32-bit on wasm32, 64-bit on wasm64
LONG_IS_64BIT = ctypes.sizeof(c_long) == 8

ONE = 1 << 16  # 1.0 in 16.16 fixed point


def deg(angle):
    """degrees -> FT_Angle (16.16 degrees)"""
    return int(angle * ONE)


def near(a, b, tol=4):
    return abs(a - b) <= tol


_FONT = """\
STARTFONT 2.1
FONT -misc-test-medium-r-normal--8-80-75-75-c-50-iso10646-1
SIZE 8 75 75
FONTBOUNDINGBOX 5 6 0 0
STARTPROPERTIES 2
FONT_ASCENT 6
FONT_DESCENT 0
ENDPROPERTIES
CHARS 2
STARTCHAR H
ENCODING 72
SWIDTH 625 0
DWIDTH 5 0
BBX 5 6 0 0
BITMAP
88
88
F8
88
88
88
ENDCHAR
STARTCHAR i
ENCODING 105
SWIDTH 250 0
DWIDTH 2 0
BBX 2 6 0 0
BITMAP
40
00
C0
40
40
E0
ENDCHAR
ENDFONT
"""


@pytest.fixture
def vera():
    face = freetype.Face(VERA)
    face.set_char_size(48 * 64)
    return face


# ---------------------------------------------------------------------------
# library / faces (FT_New_Face, FT_New_Memory_Face: FT_Long arguments)
# ---------------------------------------------------------------------------

def test_version():
    version = freetype.version()
    assert len(version) == 3
    assert version >= (2, 10, 0)


def test_new_face_properties():
    # values from upstream's tests/smoke_test.py
    face = freetype.Face(VERA)
    assert face.family_name == b"Bitstream Vera Sans"
    assert face.style_name == b"Roman"
    assert face.postscript_name == b"BitstreamVeraSans-Roman"
    assert face.get_format() == b"TrueType"
    assert face.get_fstype() == ("FT_FSTYPE_PREVIEW_AND_PRINT_EMBEDDING", 4)
    assert face.num_faces == 1
    assert face.num_glyphs == 268
    assert face.units_per_EM == 2048
    assert face.ascender == 1901
    assert face.descender == -483
    assert face.is_sfnt and face.is_scalable and face.has_kerning
    assert face.has_glyph_names
    assert not face.is_fixed_width
    bbox = face.bbox
    assert bbox.xMin < 0 < bbox.xMax and bbox.yMin < 0 < bbox.yMax


def test_new_face_from_memory():
    with open(VERA, "rb") as f:
        data = f.read()
    with open(VERA, "rb") as f:
        from_file_object = freetype.Face(f)
    from_bytes = freetype.Face.from_bytes(data)
    for face in (from_file_object, from_bytes):
        assert face.family_name == b"Bitstream Vera Sans"
        assert face.num_glyphs == 268


def test_new_face_index_and_errors(tmp_path):
    # face index 0 works, a face index past num_faces does not
    assert freetype.Face(VERA, index=0).num_glyphs == 268
    with pytest.raises(freetype.FT_Exception):
        freetype.Face(VERA, index=5)
    with pytest.raises(freetype.FT_Exception):
        freetype.Face(str(tmp_path / "does-not-exist.ttf"))
    garbage = tmp_path / "garbage.ttf"
    garbage.write_bytes(b"not a font" * 10)
    with pytest.raises(freetype.FT_Exception):
        freetype.Face(str(garbage))


def test_raw_new_face_and_memory_face():
    # call the patched functions directly with explicit FT_Long arguments
    library = freetype.get_handle()
    face = freetype.FT_Face()
    assert raw.FT_New_Face(library, VERA.encode(), 0, byref(face)) == 0
    assert face.contents.num_glyphs == 268
    assert raw.FT_Done_Face(face) == 0

    with open(VERA, "rb") as f:
        data = f.read()
    face = freetype.FT_Face()
    assert raw.FT_New_Memory_Face(library, data, len(data), 0, byref(face)) == 0
    assert face.contents.num_glyphs == 268
    assert raw.FT_Done_Face(face) == 0


# ---------------------------------------------------------------------------
# sizes (FT_Set_Char_Size: FT_F26Dot6 arguments)
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("points, dpi", [(12, 72), (12, 96), (48, 72), (100, 300)])
def test_set_char_size(points, dpi):
    face = freetype.Face(VERA)
    face.set_char_size(points * 64, points * 64, dpi, dpi)
    expected_ppem = round(points * dpi / 72)
    assert abs(face.size.x_ppem - expected_ppem) <= 1
    assert abs(face.size.y_ppem - expected_ppem) <= 1


def test_set_char_size_width_only_and_pixel_sizes():
    face = freetype.Face(VERA)
    face.set_char_size(24 * 64)  # height 0 means "same as width"
    assert face.size.x_ppem == face.size.y_ppem == 24
    face.set_pixel_sizes(0, 30)
    assert face.size.y_ppem == 30
    # ascender/descender scale with the size (26.6 values)
    assert face.size.ascender > 0 > face.size.descender


# ---------------------------------------------------------------------------
# charmaps and character codes (FT_ULong arguments / results)
# ---------------------------------------------------------------------------

def test_get_char_index():
    face = freetype.Face(VERA)
    for char in "AZaz09!?":
        index = face.get_char_index(char)
        assert index != 0
        assert face.get_char_index(ord(char)) == index
    assert face.get_char_index(0x4E2D) == 0  # CJK, not in Vera
    # the glyph name table and the cmap agree
    assert face.get_char_index("A") == face.get_name_index(b"A")
    assert face.get_glyph_name(face.get_char_index("A")) == b"A"
    assert face.get_glyph_name(20) == b"one"
    # a large (> 16-bit) char code that is not mapped
    assert face.get_char_index(0x1F600) == 0


def test_first_and_next_char():
    face = freetype.Face(VERA)
    assert face.get_first_char() == (32, 3)
    charcode, gindex = face.get_first_char()
    codes = []
    while gindex:
        codes.append(charcode)
        assert face.get_char_index(charcode) == gindex
        charcode, gindex = face.get_next_char(charcode, 0)
    assert codes == sorted(codes)
    assert ord("A") in codes and ord("z") in codes
    assert len(codes) > 200
    # the get_chars() generator ends with (0, 0)
    chars = [code for code, gindex in face.get_chars() if gindex]
    assert chars == codes


def test_raw_first_and_next_char():
    face = freetype.Face(VERA)
    agindex = freetype.FT_UInt()
    charcode = raw.FT_Get_First_Char(face._FT_Face, byref(agindex))
    assert (charcode, agindex.value) == (32, 3)
    charcode = raw.FT_Get_Next_Char(face._FT_Face, charcode, byref(agindex))
    assert charcode == 33 and agindex.value != 0


def test_charmaps():
    face = freetype.Face(VERA)
    assert face.num_charmaps == len(face.charmaps) >= 1
    face.select_charmap(freetype.FT_ENCODING_UNICODE)
    charmap = face.charmap
    assert charmap.encoding_name == "FT_ENCODING_UNICODE"
    assert charmap.cmap_format == 4  # FT_Get_CMap_Format (FT_Long result)
    assert charmap.cmap_language_id == 0  # FT_Get_CMap_Language_ID (FT_ULong)
    for cm in face.charmaps:
        assert cm.cmap_format >= 0
        assert cm.index >= 0
        face.set_charmap(cm)
        assert face.charmap.encoding == cm.encoding


def test_bdf_charmap_has_no_cmap_format(tmp_path):
    font_path = tmp_path / "test.bdf"
    font_path.write_text(_FONT)
    face = freetype.Face(str(font_path))
    # not an sfnt font: FT_Get_CMap_Format returns -1 (an FT_Long)
    assert face.charmap.cmap_format == -1


def test_chars_of_variant_selector():
    # Vera has no variation sequences: FT_Face_GetCharsOfVariant returns NULL
    face = freetype.Face(VERA)
    result = raw.FT_Face_GetCharsOfVariant(face._FT_Face, 0xFE0F)
    assert not result


# ---------------------------------------------------------------------------
# glyph loading and rendering (FT_Load_Char: FT_ULong char code)
# ---------------------------------------------------------------------------

def test_load_char_render(vera):
    vera.load_char("A")
    slot = vera.glyph
    bitmap = slot.bitmap
    assert bitmap.width > 20 and bitmap.rows > 20
    assert bitmap.pixel_mode == freetype.FT_PIXEL_MODE_GRAY
    assert bitmap.num_grays == 256
    pixels = bitmap.buffer
    assert len(pixels) == bitmap.rows * bitmap.pitch
    assert max(pixels) == 255 and min(pixels) == 0
    assert slot.advance.x > 0 and slot.advance.y == 0
    assert slot.bitmap_top > 0
    assert slot.metrics.width > 0 and slot.metrics.height > 0


def test_load_char_equals_load_glyph(vera):
    vera.load_char("g")
    by_char = (vera.glyph.bitmap.width, vera.glyph.bitmap.rows, bytes(vera.glyph.bitmap.buffer))
    vera.load_glyph(vera.get_char_index("g"))
    by_glyph = (vera.glyph.bitmap.width, vera.glyph.bitmap.rows, bytes(vera.glyph.bitmap.buffer))
    assert by_char == by_glyph


def test_render_mono(vera):
    vera.load_char("B", freetype.FT_LOAD_DEFAULT)
    vera.glyph.render(freetype.FT_RENDER_MODE_MONO)
    bitmap = vera.glyph.bitmap
    assert bitmap.pixel_mode == freetype.FT_PIXEL_MODE_MONO
    assert bitmap.pitch >= (bitmap.width + 7) // 8
    assert any(bitmap.buffer)


def test_advances_and_metrics(vera):
    # unscaled advances are in font units
    flags = freetype.FT_LOAD_NO_SCALE
    adv_i = vera.get_advance(vera.get_char_index("i"), flags)
    adv_w = vera.get_advance(vera.get_char_index("W"), flags)
    assert 0 < adv_i < adv_w <= vera.max_advance_width
    vera.load_char("W", freetype.FT_LOAD_NO_SCALE)
    assert vera.glyph.advance.x == adv_w


def test_load_char_unscaled_outline():
    face = freetype.Face(VERA)
    face.load_char("O", freetype.FT_LOAD_NO_SCALE | freetype.FT_LOAD_NO_BITMAP)
    outline = face.glyph.outline
    assert outline.n_contours == 2  # outer and inner ring
    assert len(outline.points) == outline.n_points
    assert len(outline.tags) == outline.n_points
    assert outline.contours[-1] == outline.n_points - 1
    bbox = outline.get_bbox()
    assert 0 <= bbox.xMin < bbox.xMax <= face.units_per_EM
    assert bbox.yMin < 0 < bbox.yMax


def test_outline_decompose(vera):
    vera.load_char("S", freetype.FT_LOAD_NO_BITMAP)
    events = {"move": 0, "line": 0, "conic": 0, "cubic": 0}

    def move_to(a, ctx):
        ctx["move"] += 1

    def line_to(a, ctx):
        ctx["line"] += 1

    def conic_to(a, b, ctx):
        ctx["conic"] += 1

    def cubic_to(a, b, c, ctx):
        ctx["cubic"] += 1

    vera.glyph.outline.decompose(events, move_to, line_to, conic_to, cubic_to)
    assert events["move"] == vera.glyph.outline.n_contours
    assert events["conic"] > 0  # TrueType outlines are quadratic


def test_set_transform(vera):
    vera.load_char("l")
    upright = (vera.glyph.bitmap.width, vera.glyph.bitmap.rows)
    # rotate by 90 degrees: width and height swap (roughly)
    matrix = freetype.FT_Matrix(0, -ONE, ONE, 0)
    vera.set_transform(matrix, freetype.FT_Vector(0, 0))
    vera.load_char("l")
    rotated = (vera.glyph.bitmap.width, vera.glyph.bitmap.rows)
    vera.set_transform(freetype.FT_Matrix(ONE, 0, 0, ONE), freetype.FT_Vector(0, 0))
    assert rotated[0] > upright[0] and rotated[1] < upright[1]


# ---------------------------------------------------------------------------
# kerning (FT_Get_Kerning, FT_Get_Track_Kerning: FT_Fixed)
# ---------------------------------------------------------------------------

def test_kerning(vera):
    av = vera.get_kerning("A", "V", freetype.FT_KERNING_UNSCALED)
    assert av.x < 0  # A and V move closer together
    assert vera.get_kerning("A", "V").x < 0
    assert vera.get_kerning("H", "H", freetype.FT_KERNING_UNSCALED).x == 0


def test_track_kerning():
    face = freetype.Face(VERA)
    kerning = freetype.FT_Fixed(12345)
    error = raw.FT_Get_Track_Kerning(face._FT_Face, 12 * ONE, 0, byref(kerning))
    # TrueType fonts have no track kerning: an error code or a 0 kerning
    assert isinstance(error, int)
    assert error != 0 or kerning.value == 0


# ---------------------------------------------------------------------------
# outlines (FT_Outline_Embolden, FT_Outline_EmboldenXY, FT_Outline_Translate:
# FT_Pos arguments)
# ---------------------------------------------------------------------------

def _unscaled_outline(face, char):
    face.load_char(char, freetype.FT_LOAD_NO_SCALE | freetype.FT_LOAD_NO_BITMAP)
    return face.glyph.outline


def test_outline_translate():
    face = freetype.Face(VERA)
    outline = _unscaled_outline(face, "E")
    before = outline.points
    raw.FT_Outline_Translate(byref(outline._FT_Outline), 100, -50)
    after = outline.points
    assert after == [(x + 100, y - 50) for x, y in before]
    if LONG_IS_64BIT:
        # a shift that only fits a 64-bit FT_Pos
        raw.FT_Outline_Translate(byref(outline._FT_Outline), 1 << 33, 0)
        assert outline.points[0][0] == before[0][0] + 100 + (1 << 33)


def test_outline_embolden():
    face = freetype.Face(VERA)
    outline = _unscaled_outline(face, "I")
    bbox = outline.get_bbox()
    width = bbox.xMax - bbox.xMin
    assert raw.FT_Outline_Embolden(byref(outline._FT_Outline), 64) == 0
    bbox = outline.get_bbox()
    assert bbox.xMax - bbox.xMin == width + 64

    outline = _unscaled_outline(face, "I")
    bbox = outline.get_bbox()
    width, height = bbox.xMax - bbox.xMin, bbox.yMax - bbox.yMin
    if hasattr(raw, "FT_Outline_EmboldenXY"):
        assert raw.FT_Outline_EmboldenXY(byref(outline._FT_Outline), 40, 100) == 0
        bbox = outline.get_bbox()
        assert bbox.xMax - bbox.xMin == width + 40
        assert bbox.yMax - bbox.yMin == height + 100


# ---------------------------------------------------------------------------
# glyphs and stroker (FT_Stroker_Set: FT_Fixed arguments)
# ---------------------------------------------------------------------------

def test_glyph_to_bitmap(vera):
    vera.load_char("A", freetype.FT_LOAD_DEFAULT)
    glyph = vera.glyph.get_glyph()
    bitmap_glyph = glyph.to_bitmap(freetype.FT_RENDER_MODE_NORMAL, 0)
    bitmap = bitmap_glyph.bitmap
    assert bitmap.width > 0 and bitmap.rows > 0 and any(bitmap.buffer)


def _stroked_width(face, radius):
    face.load_char("O", freetype.FT_LOAD_DEFAULT | freetype.FT_LOAD_NO_BITMAP)
    glyph = face.glyph.get_glyph()
    if radius:
        stroker = freetype.Stroker()
        stroker.set(radius, freetype.FT_STROKER_LINECAP_ROUND,
                    freetype.FT_STROKER_LINEJOIN_ROUND, 0)
        glyph.stroke(stroker, True)
    return glyph.to_bitmap(freetype.FT_RENDER_MODE_NORMAL, 0, True).bitmap.width


def test_stroker(vera):
    plain = _stroked_width(vera, 0)
    thin = _stroked_width(vera, 2 * 64)
    thick = _stroked_width(vera, 6 * 64)
    assert plain < thin < thick


def test_glyph_to_bitmap_with_origin(vera):
    # FT_Glyph_To_Bitmap with a FT_Vector origin (a pointer) instead of 0
    widths = []
    for origin_x in (0, 32):  # 26.6: shift by half a pixel
        vera.load_char("I", freetype.FT_LOAD_DEFAULT | freetype.FT_LOAD_NO_BITMAP)
        glyph = vera.glyph.get_glyph()
        bitmap_glyph = glyph.to_bitmap(freetype.FT_RENDER_MODE_NORMAL,
                                       freetype.FT_Vector(origin_x, 0))
        widths.append(bitmap_glyph.bitmap.width)
        assert any(bitmap_glyph.bitmap.buffer)
    assert widths[0] > 0 and widths[1] > 0


def test_glyph_stroke_border(vera):
    # outside border only: wider than the plain glyph, a ring for "O"
    vera.load_char("O", freetype.FT_LOAD_DEFAULT | freetype.FT_LOAD_NO_BITMAP)
    plain = vera.glyph.get_glyph().to_bitmap(freetype.FT_RENDER_MODE_NORMAL, 0).bitmap.width

    vera.load_char("O", freetype.FT_LOAD_DEFAULT | freetype.FT_LOAD_NO_BITMAP)
    glyph = vera.glyph.get_glyph()
    stroker = freetype.Stroker()
    stroker.set(3 * 64, freetype.FT_STROKER_LINECAP_ROUND,
                freetype.FT_STROKER_LINEJOIN_ROUND, 0)
    error = raw.FT_Glyph_StrokeBorder(byref(glyph._FT_Glyph), stroker._FT_Stroker,
                                      False, True)
    assert error == 0
    bordered = glyph.to_bitmap(freetype.FT_RENDER_MODE_NORMAL, 0).bitmap.width
    assert bordered > plain


# ---------------------------------------------------------------------------
# sfnt tables and names (FT_Get_Sfnt_Table returns a pointer)
# ---------------------------------------------------------------------------

class _TTHeader(Structure):
    # beginning of FreeType's TT_Header: FT_Fixed / FT_Long are C long
    _fields_ = [
        ("Table_Version", c_long),
        ("Font_Revision", c_long),
        ("CheckSum_Adjust", c_long),
        ("Magic_Number", c_long),
        ("Flags", c_ushort),
        ("Units_Per_EM", c_ushort),
    ]


def test_sfnt_head_table():
    face = freetype.Face(VERA)
    pointer = raw.FT_Get_Sfnt_Table(face._FT_Face, 0)  # FT_SFNT_HEAD
    assert pointer  # a full pointer, not truncated to an int
    head = cast(pointer, POINTER(_TTHeader)).contents
    assert head.Table_Version == ONE
    assert head.Magic_Number == 0x5F0F3CF5
    assert head.Units_Per_EM == 2048


def test_sfnt_names():
    face = freetype.Face(VERA)
    count = face.sfnt_name_count
    assert count > 5
    names = [face.get_sfnt_name(i) for i in range(count)]
    family = [n.string for n in names if n.name_id == 1 and n.platform_id == 1]
    assert family == [b"Bitstream Vera Sans"]
    assert face.get_best_name_string(1) == "Bitstream Vera Sans"


# ---------------------------------------------------------------------------
# fixed width font
# ---------------------------------------------------------------------------

def test_fixed_width_font():
    face = freetype.Face(VERA_MONO)
    assert face.is_fixed_width
    flags = freetype.FT_LOAD_NO_SCALE
    advances = {face.get_advance(face.get_char_index(c), flags) for c in "iWm.@"}
    assert len(advances) == 1


# ---------------------------------------------------------------------------
# variable font (from upstream's tests/vf_test.py)
# ---------------------------------------------------------------------------

def test_variable_font_info():
    face = freetype.Face(SOURCE_SANS_VF)
    info = face.get_variation_info()
    assert len(info.axes) == 1
    assert info.axes[0].tag == "wght"
    assert [inst.coords for inst in info.instances] == [
        (200,), (300,), (400,), (600,), (700,), (900,)
    ]


def test_variable_font_coords():
    face = freetype.Face(SOURCE_SANS_VF)
    face.set_var_design_coords((373,))
    assert face.get_var_design_coords()[0] == 373
    face.set_var_blend_coords((-0.5,))
    assert face.get_var_blend_coords()[0] == -0.5
    face.set_var_design_coords(None, reset=True)
    info = face.get_variation_info()
    assert face.get_var_design_coords() == (info.axes[0].default,)
    # reset via the blend coordinates: FT_Set_Var_Blend_Coordinates(face, 0, NULL)
    face.set_var_blend_coords((0.5,))
    assert face.get_var_blend_coords()[0] == 0.5
    face.set_var_blend_coords(None, reset=True)
    (blend,) = face.get_var_blend_coords()
    assert -1.0 <= blend <= 1.0
    (design,) = face.get_var_design_coords()
    assert info.axes[0].minimum <= design <= info.axes[0].maximum


def test_variable_font_named_instances_change_glyphs():
    face = freetype.Face(SOURCE_SANS_VF)
    face.set_char_size(48 * 64)
    info = face.get_variation_info()
    ink = []
    for inst in (info.instances[0], info.instances[-1]):  # ExtraLight, Black
        face.set_var_named_instance(inst.name)
        assert face.get_var_design_coords() == inst.coords
        face.load_char("H")
        ink.append(sum(face.glyph.bitmap.buffer))
    assert ink[0] < ink[1]


# ---------------------------------------------------------------------------
# fixed point math (FT_Long / FT_Fixed / FT_Angle in and out)
# ---------------------------------------------------------------------------

def test_fixed_point_arithmetic():
    assert raw.FT_MulFix(3 * ONE, 2 * ONE) == 6 * ONE
    assert raw.FT_MulFix(-3 * ONE, ONE // 2) == -3 * ONE // 2
    assert raw.FT_DivFix(6 * ONE, 4 * ONE) == 3 * ONE // 2
    assert raw.FT_MulDiv(1000, 3000, 1500) == 2000
    assert raw.FT_MulDiv(-7, 9, 3) == -21
    assert raw.FT_RoundFix(ONE + ONE // 2) == 2 * ONE
    assert raw.FT_CeilFix(ONE + 1) == 2 * ONE
    assert raw.FT_FloorFix(2 * ONE - 1) == ONE
    assert raw.FT_FloorFix(-ONE // 2) == -ONE


@pytest.mark.skipif(not LONG_IS_64BIT, reason="C long is 32-bit")
def test_fixed_point_arithmetic_64bit():
    # results that only fit a 64-bit FT_Long
    assert raw.FT_MulDiv(1 << 40, 3, 2) == 3 << 39
    assert raw.FT_MulFix(1 << 40, 4 * ONE) == 1 << 42
    assert raw.FT_DivFix(1 << 40, ONE) == 1 << 40


def test_trigonometry():
    assert near(raw.FT_Cos(0), ONE)
    assert near(raw.FT_Sin(deg(90)), ONE)
    assert near(raw.FT_Sin(deg(30)), ONE // 2)
    assert near(raw.FT_Cos(deg(180)), -ONE)
    assert near(raw.FT_Tan(deg(45)), ONE)
    assert near(raw.FT_Atan2(ONE, ONE), deg(45), tol=16)
    # +-180 degrees: compare modulo 360 via FT_Angle_Diff
    assert near(raw.FT_Angle_Diff(raw.FT_Atan2(-ONE, 0), deg(180)), 0, tol=16)
    assert near(raw.FT_Atan2(0, -ONE), deg(-90), tol=16)
    assert raw.FT_Angle_Diff(deg(10), deg(350)) == deg(-20)
    assert raw.FT_Angle_Diff(deg(350), deg(10)) == deg(20)


def test_vectors():
    v = freetype.FT_Vector(3 * ONE, 4 * ONE)
    assert near(raw.FT_Vector_Length(byref(v)), 5 * ONE)

    unit = freetype.FT_Vector(0, 0)
    raw.FT_Vector_Unit(byref(unit), deg(90))
    assert near(unit.x, 0) and near(unit.y, ONE)

    v = freetype.FT_Vector(2 * ONE, 0)
    raw.FT_Vector_Rotate(byref(v), deg(90))
    assert near(v.x, 0, tol=8) and near(v.y, 2 * ONE, tol=8)

    polar = freetype.FT_Vector(0, 0)
    raw.FT_Vector_From_Polar(byref(polar), 2 * ONE, deg(180))
    assert near(polar.x, -2 * ONE, tol=8) and near(polar.y, 0, tol=8)


# ---------------------------------------------------------------------------
# bitmap (BDF) font, rendered to a small canvas
# ---------------------------------------------------------------------------

def test_render_text_to_bitmap(tmp_path):
    font_path = tmp_path / "test.bdf"
    font_path.write_text(_FONT)

    face = freetype.Face(str(font_path))
    face.set_pixel_sizes(0, 8)

    rendered = []
    pen_positions = []
    pen_x = 0
    for character in "Hi":
        face.load_char(character, freetype.FT_LOAD_RENDER)
        bitmap = face.glyph.bitmap
        pixels = bytes(bitmap.buffer)

        assert bitmap.width > 0
        assert bitmap.rows > 0
        assert any(pixels)
        advance = face.glyph.advance.x >> 6
        rendered.append(
            (
                face.glyph.bitmap_left,
                bitmap.width,
                bitmap.rows,
                bitmap.pitch,
                pixels,
                advance,
            )
        )
        pen_positions.append(pen_x)
        pen_x += advance

    height = max(item[2] for item in rendered)
    canvas_width = max(
        pen_x + left + bitmap_width
        for pen_x, (left, bitmap_width, *_rest) in zip(pen_positions, rendered)
    )
    canvas = bytearray(canvas_width * height)
    x = 0
    for left, bitmap_width, bitmap_rows, pitch, pixels, advance in rendered:
        for row in range(bitmap_rows):
            start = row * abs(pitch)
            for column in range(bitmap_width):
                destination = x + left + column
                source = start + column
                if 0 <= destination < canvas_width and source < len(pixels):
                    canvas[row * canvas_width + destination] = pixels[source]
        x += advance

    assert x == pen_x
    assert len(canvas) == canvas_width * height
    assert sum(canvas) > 0


def test_bdf_long_arguments(tmp_path):
    font_path = tmp_path / "test.bdf"
    font_path.write_text(_FONT)
    face = freetype.Face(str(font_path))
    with open(font_path, "rb") as f:
        memory_face = freetype.Face(f)
    assert memory_face.num_glyphs == face.num_glyphs
    assert face.get_char_index("H") != 0
    assert face.get_char_index("x") == 0
    assert [chr(c) for c, g in face.get_chars() if g] == ["H", "i"]
