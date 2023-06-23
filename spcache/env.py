"""Improvements to the parsing functionality of the dotenv module."""

import os
import shutil
import tempfile
import typing as t
from contextlib import contextmanager

import dotenv.main


class InvalidLineError(Exception):
    """Raised when a line in a .env file is invalid."""

    def __init__(self, line_no: int, line_content: str) -> None:
        self.line_no = line_no
        self.line_content = line_content


@contextmanager
def rewrite(
    path: dotenv.main.StrPath,
    encoding: t.Optional[str],
) -> t.Iterator[t.Tuple[t.TextIO, t.TextIO]]:
    """Make changes to a file atomically."""
    if not os.path.isfile(path):
        with open(path, mode="w", encoding=encoding) as source:
            pass

    dest_file = tempfile.NamedTemporaryFile(mode="w", encoding=encoding, delete=False)

    try:
        source = open(path, encoding=encoding)  # noqa: SIM115
    except BaseException:
        dest_file.close()
        os.unlink(dest_file.name)
        raise

    try:
        yield (source, dest_file)
    except BaseException:
        failed = True
        raise
    else:
        failed = False
    finally:
        dest_file.close()
        source.close()
        if failed:
            os.unlink(dest_file.name)
        else:
            shutil.move(dest_file.name, path)


def set_key(
    dotenv_path: dotenv.main.StrPath,
    key_to_set: str,
    value_to_set: str,
    quote_mode: t.Literal["always", "auto", "never"] = "always",
    export: bool = False,
    encoding: t.Optional[str] = "utf-8",
    ignore_errors: bool = False,
) -> t.Optional[str]:
    """
    Add or update a key/value pair in the given .env.

    If the .env path given doesn't exist, fails instead of risking creating
    an orphan .env somewhere in the filesystem.

    If ignore_errors is True, invalid lines in the .env will be ignored.

    Returns None if the key/value pair was added, or the previous value if
    the key/value pair was updated.
    """
    if quote_mode not in ("always", "auto", "never"):
        raise ValueError(f"Unknown quote_mode: {quote_mode}")

    quote = quote_mode == "always" or (quote_mode == "auto" and not value_to_set.isalnum())

    value_out = "'{}'".format(value_to_set.replace("'", "\\'")) if quote else value_to_set
    line_out = f"export {key_to_set}={value_out}\n" if export else f"{key_to_set}={value_out}\n"
    previous_value = None

    with rewrite(dotenv_path, encoding=encoding) as (source, dest):
        replaced = False
        missing_newline = False
        for mapping in dotenv.main.parse_stream(source):
            if not ignore_errors and mapping.error:
                raise InvalidLineError(mapping.original.line, mapping.original.string)

            if mapping.key == key_to_set:
                dest.write(line_out)
                replaced = True
                previous_value = mapping.value
            else:
                dest.write(mapping.original.string)
                missing_newline = not mapping.original.string.endswith("\n")
        if not replaced:
            if missing_newline:
                dest.write("\n")
            dest.write(line_out)

    return previous_value


def get_key(
    dotenv_path: dotenv.main.StrPath,
    key: str,
    ignore_errors: bool = False,
) -> t.Optional[str]:
    """
    Obtain a key's value from the given .env file.

    If the key doesn't exist, None is returned.
    If ignore_errors is True, invalid lines in the file will be ignored.
    """
    with open(dotenv_path) as stream:
        for mapping in dotenv.main.parse_stream(stream):
            if not ignore_errors and mapping.error:
                raise InvalidLineError(mapping.original.line, mapping.original.string)

            if mapping.key == key:
                return mapping.value

    return None
