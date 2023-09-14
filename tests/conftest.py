import pytest
from platform import system
from pathlib import Path
from os.path import splitdrive, join
from os import listdir
from random import randint, choices
from string import ascii_lowercase

from spcache.detect import WIN_PATHS, UNIX_PATHS


@pytest.fixture()
def system_fixture():
    """Check and save type of working operational system."""
    return system()


@pytest.fixture()
def prepare_paths():
    """Prepare and save paths to detect."""
    check = system()
    outcome = WIN_PATHS if check == "Windows" else UNIX_PATHS
    return outcome


@pytest.fixture()
def create_random_path():
    """Create random path which exist in file system."""
    current_dir = Path(__file__).absolute()
    drive, rest = splitdrive(current_dir)
    if system() == "Windows":
        formatted_drive = join(drive, "\\")
    else:
        formatted_drive = join(drive, "/")
    list_dir = listdir(formatted_drive)
    if len(list_dir) > 0:
        random_number = randint(0, len(list_dir))
        final_path = Path(formatted_drive + list_dir[random_number])
    else:
        final_path = Path(formatted_drive)
    return final_path


@pytest.fixture()
def create_non_existing_path():
    """Create path which doesn't exist in file system."""
    current_dir = Path(__file__).absolute()
    drive, rest = splitdrive(current_dir)
    if system() == "Windows":
        formatted_drive = join(drive, "\\")
    else:
        formatted_drive = join(drive, "/")
    list_dir = listdir(formatted_drive)
    appendix = choices(ascii_lowercase)
    for character in appendix:
        if character not in list_dir:
            final_path = Path(formatted_drive + character)
    return final_path
