import os
from empack.file_patterns import pkg_file_filter_from_yaml

from pathlib import Path


# this test will complain if the empack config is broken
def test_empack_config():

    THIS_DIR = os.path.dirname(os.path.realpath(__file__))
    PARENT_DIR = Path(THIS_DIR).parent
    CONFIG_PATH = os.path.join(PARENT_DIR, "empack_config.yaml")
    PKG_FILE_FILTER = pkg_file_filter_from_yaml(CONFIG_PATH)
