"""Improvements to the parsing functionality of the dotenv module."""

import typing as t

import dotenv.main


class InvalidLineError(Exception):
    """Raised when a line in a .env file is invalid."""

    def __init__(self, line_no: int, line_content: str) -> None:
        self.line_no = line_no
        self.line_content = line_content


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

    with dotenv.main.rewrite(dotenv_path, encoding=encoding) as (source, dest):
        replaced = False
        missing_newline = False
        for mapping in dotenv.main.parse_stream(source):
            if not ignore_errors:
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
