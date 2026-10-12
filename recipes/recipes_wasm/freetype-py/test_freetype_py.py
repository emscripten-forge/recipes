import freetype


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
