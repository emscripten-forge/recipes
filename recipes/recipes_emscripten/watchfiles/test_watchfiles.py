import os
from pathlib import Path
from time import sleep
from threading import Thread
from functools import wraps


def test_basic():
    # watch cannot be tested without multithreading
    from watchfiles import Change, watch
