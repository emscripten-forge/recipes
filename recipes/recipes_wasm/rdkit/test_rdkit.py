import io


def test_smiles_descriptors_fingerprints():
    from rdkit import Chem, DataStructs
    from rdkit.Chem import AllChem, Descriptors, rdFingerprintGenerator

    aspirin = Chem.MolFromSmiles("CC(=O)Oc1ccccc1C(=O)O")
    assert aspirin.GetNumAtoms() == 13
    assert abs(Descriptors.MolWt(aspirin) - 180.159) < 0.01
    assert Chem.MolToSmiles(aspirin) == "CC(=O)Oc1ccccc1C(=O)O"

    salicylic = Chem.MolFromSmiles("O=C(O)c1ccccc1O")
    gen = rdFingerprintGenerator.GetMorganGenerator(radius=2, fpSize=2048)
    fp1 = gen.GetFingerprint(aspirin)
    fp2 = gen.GetFingerprint(salicylic)
    sim = DataStructs.TanimotoSimilarity(fp1, fp2)
    assert 0.0 < sim < 1.0
    assert DataStructs.TanimotoSimilarity(fp1, fp1) == 1.0

    # substructure search
    assert aspirin.HasSubstructMatch(Chem.MolFromSmarts("c1ccccc1"))

    # 3D embedding
    mh = Chem.AddHs(aspirin)
    assert AllChem.EmbedMolecule(mh, randomSeed=42) == 0
    assert mh.GetNumConformers() == 1


def test_svg_drawing():
    from rdkit import Chem
    from rdkit.Chem.Draw import rdMolDraw2D

    mol = Chem.MolFromSmiles("CN1C=NC2=C1C(=O)N(C(=O)N2C)C")  # caffeine
    d = rdMolDraw2D.MolDraw2DSVG(300, 300)
    d.DrawMolecule(mol)
    d.FinishDrawing()
    svg = d.GetDrawingText()
    assert svg.startswith("<?xml")
    assert "</svg>" in svg
    assert "<path" in svg


def test_notebook_display():
    from PIL import Image
    from rdkit import Chem
    from rdkit.Chem import Draw
    from rdkit.Chem.Draw import IPythonConsole  # noqa: F401 (installs _repr_*_)

    mol = Chem.MolFromSmiles("c1ccccc1O")

    png = mol._repr_png_()
    assert png[:8] == b"\x89PNG\r\n\x1a\n"
    assert len(png) > 1000

    IPythonConsole.ipython_useSVG = True
    svg = mol._repr_svg_()
    assert "</svg>" in svg and "<path" in svg
    IPythonConsole.ipython_useSVG = False

    mols = [Chem.MolFromSmiles(s) for s in ["CCO", "c1ccccc1", "CC(=O)O", "C1CCCCC1"]]
    img = Draw.MolsToGridImage(mols, molsPerRow=2, subImgSize=(150, 150),
                               legends=["ethanol", "benzene", "acetic acid", "cyclohexane"])
    if not isinstance(img, Image.Image):
        # inside IPython the grid is returned as an IPython Image object
        img = Image.open(io.BytesIO(img.data))
    assert img.size == (300, 300)
    # the image is not blank
    assert len(set(img.convert("L").getdata())) > 2

    grid_svg = Draw.MolsToGridImage(mols, molsPerRow=2, useSVG=True)
    # inside IPython this is an IPython.display.SVG object
    grid_svg = getattr(grid_svg, "data", grid_svg)
    assert "</svg>" in grid_svg and "<path" in grid_svg
