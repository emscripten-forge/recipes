import array

import pysam

SAM_TEXT = (
    "@HD\tVN:1.6\tSO:coordinate\n"
    "@SQ\tSN:seq1\tLN:1000\n"
    "@SQ\tSN:seq2\tLN:500\n"
    "read1\t0\tseq1\t101\t60\t10M\t*\t0\t0\tACGTACGTAC\tIIIIIIIIII\tNM:i:0\n"
    "read2\t16\tseq1\t201\t60\t10M\t*\t0\t0\tGGGGCCCCAA\tIIIIIIIIII\n"
    "read3\t0\tseq2\t51\t30\t5M\t*\t0\t0\tACGTA\tIIIII\n"
)


def _make_bam(prefix):
    with open(prefix + ".sam", "w") as fh:
        fh.write(SAM_TEXT)
    # catch_stdout=False keeps the explicit -o; otherwise pysam appends its own -o
    pysam.view("-b", "-o", prefix + ".bam", prefix + ".sam", catch_stdout=False)
    pysam.sort("-o", prefix + ".sorted.bam", prefix + ".bam")
    pysam.index(prefix + ".sorted.bam")
    return prefix + ".sorted.bam"


def test_version():
    assert pysam.__version__ == "0.24.1"


def test_bam_header_references():
    path = _make_bam("header_test")
    with pysam.AlignmentFile(path, "rb") as f:
        assert f.references == ("seq1", "seq2")
        assert f.lengths == (1000, 500)


def test_fetch_all_reads_in_contig():
    path = _make_bam("fetch_test")
    with pysam.AlignmentFile(path, "rb") as f:
        names = [r.query_name for r in f.fetch("seq1")]
    assert names == ["read1", "read2"]


def test_fetch_region():
    path = _make_bam("region_test")
    with pysam.AlignmentFile(path, "rb") as f:
        names = [r.query_name for r in f.fetch("seq1", 100, 120)]
    assert names == ["read1"]


def test_aligned_segment_fields():
    path = _make_bam("fields_test")
    with pysam.AlignmentFile(path, "rb") as f:
        reads = {r.query_name: r for r in f.fetch()}
    assert reads["read1"].reference_start == 100
    assert reads["read1"].cigarstring == "10M"
    assert reads["read1"].get_tag("NM") == 0
    assert reads["read2"].is_reverse
    assert reads["read2"].query_sequence == "GGGGCCCCAA"


def test_flagstat():
    path = _make_bam("flagstat_test")
    output = pysam.flagstat(path)
    assert "3 + 0 in total" in output


def test_create_aligned_segment_in_memory():
    seg = pysam.AlignedSegment()
    seg.query_name = "mem_read"
    seg.query_sequence = "ACGT"
    seg.flag = 0
    seg.reference_id = -1
    seg.cigartuples = [(0, 4)]
    seg.query_qualities = array.array("B", [40, 40, 40, 40])
    assert seg.query_length == 4
    assert seg.cigarstring == "4M"
    assert list(seg.query_qualities) == [40, 40, 40, 40]
