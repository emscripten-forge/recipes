def test_profiler_session_round_trip():
    import json
    import os
    import tempfile

    from pyinstrument.profiler import Profiler, Session

    profiler = Profiler()
    with profiler:
        sum(i * i for i in range(100000))
    profiler.print(show_all=True, timeline=True)

    session = profiler.last_session
    assert session is not None

    with tempfile.TemporaryDirectory() as tmpdir:
        session_file = os.path.join(tmpdir, "profile.pysession")
        session.save(session_file)
        with open(session_file) as f:
            data = json.load(f)
        loaded = Session.load(session_file)

    expected_keys = {
        "cpu_time",
        "duration",
        "frame_records",
        "sample_count",
        "start_call_stack",
        "start_time",
    }
    assert not expected_keys - set(data)
    assert json.dumps(loaded.to_json(), sort_keys=True) == json.dumps(
        json.loads(json.dumps(data)), sort_keys=True
    )
