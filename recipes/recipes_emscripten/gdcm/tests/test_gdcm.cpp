#include <gdcmAttribute.h>
#include <gdcmDataSet.h>
#include <gdcmFile.h>
#include <gdcmStringFilter.h>
#include <gdcmGlobal.h>
#include <gdcmDicts.h>
#include <gdcmUIDGenerator.h>
#include <gdcmMediaStorage.h>
#include <gdcmTransferSyntax.h>
#include <gdcmVR.h>
#include <gdcmTag.h>
#include <iostream>
#include <cassert>

int main() {
    // 1. Verify DICOM dictionary loads
    gdcm::Global& g = gdcm::Global::GetInstance();
    assert(g.LoadResourcesFiles() && "Global resources should load");

    const gdcm::Dicts& dicts = g.GetDicts();
    const gdcm::Dict& pubDict = dicts.GetPublicDict();

    // 2. Look up a known tag in the dictionary
    gdcm::DictEntry entry;
    assert(pubDict.GetDictEntry(gdcm::Tag(0x0010, 0x0010), entry)
           && "PatientName should be in dictionary");
    assert(entry.GetVR() == gdcm::VR::PN && "PatientName VR should be PN");
    assert(strcmp(entry.GetName(), "Patient's Name") == 0);

    // 3. Create a DataSet and insert typed attributes
    gdcm::DataSet ds;

    // Patient Name (PN)
    {
        gdcm::Attribute<0x0010, 0x0010> at;
        at.SetValue("Test^Patient");
        ds.Insert(at.GetAsDataElement());
    }

    // Study Date (DA)
    {
        gdcm::Attribute<0x0008, 0x0020> at;
        at.SetValue("20260101");
        ds.Insert(at.GetAsDataElement());
    }

    // Modality (CS)
    {
        gdcm::Attribute<0x0008, 0x0060> at;
        at.SetValue("CT");
        ds.Insert(at.GetAsDataElement());
    }

    // Patient ID (LO)
    {
        gdcm::Attribute<0x0010, 0x0020> at;
        at.SetValue("GDCM-TEST-001");
        ds.Insert(at.GetAsDataElement());
    }

    // 4. Read back attributes
    {
        gdcm::Attribute<0x0010, 0x0010> at;
        at.SetFromDataSet(ds);
        assert(at.GetValue() == "Test^Patient" && "PatientName mismatch");
    }
    {
        gdcm::Attribute<0x0008, 0x0020> at;
        at.SetFromDataSet(ds);
        assert(at.GetValue() == "20260101" && "StudyDate mismatch");
    }
    {
        gdcm::Attribute<0x0008, 0x0060> at;
        at.SetFromDataSet(ds);
        assert(at.GetValue() == "CT" && "Modality mismatch");
    }
    {
        gdcm::Attribute<0x0010, 0x0020> at;
        at.SetFromDataSet(ds);
        assert(at.GetValue() == "GDCM-TEST-001" && "PatientID mismatch");
    }

    // 5. Verify StringFilter works (requires File wrapper)
    gdcm::File file;
    file.SetDataSet(ds);
    gdcm::StringFilter sf;
    sf.SetFile(file);
    std::string pnStr = sf.ToString(gdcm::Tag(0x0010, 0x0010));
    assert(pnStr == "Test^Patient" && "StringFilter PatientName mismatch");

    // 6. Verify UID generation produces non-empty strings
    gdcm::UIDGenerator uidGen;
    std::string uid = uidGen.Generate();
    assert(!uid.empty() && "UID should not be empty");
    assert(uid.length() > 10 && "UID should be reasonably long");

    // 7. Verify MediaStorage and TransferSyntax enums
    gdcm::MediaStorage ms;
    ms.SetFromModality(ds);
    (void)ms;  // Silence unused warning if not used further

    gdcm::TransferSyntax ts =
        gdcm::TransferSyntax::ExplicitVRLittleEndian;
    assert(ts.IsExplicit() && "ExplicitVRLittleEndian should be explicit");
    assert(!ts.IsLossy() && "ExplicitVRLittleEndian should not be lossy");

    // 8. VR byte lengths
    assert(gdcm::VR::GetLength(gdcm::VR::UI) == 64
           && "UI max length should be 64");
    assert(gdcm::VR::GetLength(gdcm::VR::DA) == 8
           && "DA max length should be 8");

    std::cout << "All tests passed!" << std::endl;
    return 0;
}
