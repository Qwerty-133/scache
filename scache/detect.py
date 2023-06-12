"""Make a best-effort guess at location of the users Spotify prefs file."""

import pathlib
import platform
import typing as t

import click

win_str_paths = [
    "~/AppData/Roaming/Spotify/prefs",
]
WIN_PATHS = [pathlib.Path(path).expanduser() for path in win_str_paths]


unix_str_paths = [
    "~/.config/spotify/prefs",
    "~/snap/spotify/current/.config/spotify/prefs",
]
UNIX_PATHS = [pathlib.Path(path).expanduser() for path in unix_str_paths]


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

    import subprocess

    cmd = "find ~ | grep 'spotify/prefs' | head -n 1"
    click.echo(f"Running: {cmd}")
    try:
        process = subprocess.run(
            cmd, shell=True, check=True, capture_output=True, encoding="utf-8"  # noqa: S602
        )
    except subprocess.CalledProcessError:
        return None
    else:
        path = pathlib.Path(process.stdout.strip())
        if ensure_file(path):
            return normalize_path(path)


def detect_prefs_file() -> t.Optional[str]:
    """Return the path to the Spotify prefs file, if found."""
    if platform.system() == "Windows":
        return win_strategy()

    return unix_strategy()
