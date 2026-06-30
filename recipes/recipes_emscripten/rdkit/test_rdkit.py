def test_import():
    from rdkit import Chem
    mol = Chem.MolFromSmiles('CCO')
    assert mol is not None
    assert mol.GetNumAtoms() == 3


def test_smiles_roundtrip():
    from rdkit import Chem
    smi = 'c1ccccc1'
    mol = Chem.MolFromSmiles(smi)
    assert mol is not None
    out = Chem.MolToSmiles(mol)
    assert out == 'c1ccccc1'


def test_fingerprint():
    from rdkit.Chem import AllChem, DataStructs
    mol = AllChem.MolFromSmiles('CCO')
    fp = AllChem.GetMorganFingerprintAsBitVect(mol, 2, nBits=1024)
    assert fp.GetNumBits() == 1024
