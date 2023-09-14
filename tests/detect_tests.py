"""
tests for detect.py
"""

import pytest
from pathlib import Path

import spcache.detect as de
from conftest import system_fixture, create_random_path, create_non_existing_path


@pytest.fixture()
def current_dir_fixture():
    """Return current directory."""
    return Path(__file__).absolute()


def test_paths_existing():
    """Check whether exists at least one path."""
    assert (len(de.UNIX_PATHS) > 0) or (len(de.WIN_PATHS) > 0)


def test_ensure(current_dir_fixture, create_non_existing_path):
    """Function checks whether detect.ensure() function works properly with current or false directory."""
    current_dir = current_dir_fixture
    false_path = create_non_existing_path
    assert de.ensure_file(current_dir) is True
    assert de.ensure_file(false_path) is False


def test_normalization_current_dir(current_dir_fixture):
    """Function checks whether current directory will be properly formatted."""
    current_dir = current_dir_fixture
    outcome = de.normalize_path(current_dir)
    assert type(outcome) == str


def test_normalization_random_path(create_random_path):
    """Test normalization by random path."""
    path = create_random_path
    outcome = de.normalize_path(path)
    assert type(outcome) == str


def test_win_strategy(system_fixture):
    """Base tests for win_strategy function."""
    if system_fixture == "Windows":
        assert type(de.win_strategy()) == str
    else:
        assert type(de.win_strategy()) is None
    assert de.win_strategy()


def test_unix_strategy(system_fixture):
    """Base tests for unix_strategy function."""
    if system_fixture != "Windows":
        assert type(de.unix_strategy()) == str
    else:
        assert type(de.unix_strategy()) != str


def test_detect_prefs_file(system_fixture):
    """Check whether detect_prefs_file function apply appropriate option for current operational system."""
    if (len(de.UNIX_PATHS) > 0) or (len(de.WIN_PATHS) > 0):
        assert type(de.detect_prefs_file()) == str
    else:
        assert de.detect_prefs_file() is None
    assert de.detect_prefs_file()
