"""Make a best-effort guess at location of the users Spotify prefs file."""

import pathlib
import platform
import typing as t

import click

WIN_PATHS = map(
    pathlib.Path,
    [
        "~/AppData/Roaming/Spotify/prefs",
    ],
)


UNIX_PATHS = []


def ensure_file(path: pathlib.Path) -> bool:
    """Ensure that the path exists and is a file."""
    return path.exists() and path.is_file()


def normalize_path(path: pathlib.Path) -> str:
    """Normalize the path to a string after resolving it."""
    return str(path.resolve())


def win_strategy() -> t.Optional[str]:
    """
    Try finding the prefs file for a Windows platform.

    Handles direct installations, Windows Store installations, and
    Winget installations.
    """
    for path in WIN_PATHS:
        path = path.expanduser()
        if ensure_file(path):
            return normalize_path(path)

    localpkgs = pathlib.Path("~/AppData/Local/Packages").expanduser()
    try:
        (match,) = [*localpkgs.glob("Spotify*")]
    except ValueError:
        pass
    else:
        if match.is_dir():
            path = match / "LocalState" / "Spotify" / "prefs"
            if ensure_file(path):
                return normalize_path(path)

    return None


def unix_strategy() -> t.Optional[str]:
    """Try finding the prefs file for a Unix platform."""
    for path in UNIX_PATHS:
        if ensure_file(path):
            return normalize_path(path)

    return None


def detect_prefs_file(
    ctx: click.Context,
) -> t.Optional[str]:
    """Return the path to the Spotify prefs file, if found."""
    if platform.system() == "Windows":
        return win_strategy()

    return unix_strategy()
