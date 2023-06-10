"""Improvements to the parsing functionality of the dotenv module."""

import typing as t

import click
import dotenv.main


def set_cache_size(
    ctx: click.Context,
    dotenv_path: dotenv.main.StrPath,
    key_to_set: str,
    value_to_set: str,
    quote_mode: t.Literal["always", "auto", "never"] = "always",
    export: bool = False,
    encoding: t.Optional[str] = "utf-8",
    force: bool = False,
) -> t.Tuple[t.Optional[bool], str, str]:
    """
    Add or update a key/value pair in the given .env.

    If the .env path given doesn't exist, fails instead of risking creating
    an orphan .env somewhere in the filesystem
    """
    if quote_mode not in ("always", "auto", "never"):
        raise ValueError(f"Unknown quote_mode: {quote_mode}")

    quote = quote_mode == "always" or (quote_mode == "auto" and not value_to_set.isalnum())

    value_out = "'{}'".format(value_to_set.replace("'", "\\'")) if quote else value_to_set
    line_out = f"export {key_to_set}={value_out}\n" if export else f"{key_to_set}={value_out}\n"
    previous_cache_size = None

    with dotenv.main.rewrite(dotenv_path, encoding=encoding) as (source, dest):
        replaced = False
        missing_newline = False
        for mapping in dotenv.main.parse_stream(source):
            if not force and mapping.error:
                import textwrap

                line_preview = textwrap.shorten(mapping.original.string.rstrip(), 80)
                ctx.fail(
                    f"Line {mapping.original.line} is invalid. ({line_preview})"
                    "\nTo ignore this error, use the --force flag."
                )

            if mapping.key == key_to_set:
                dest.write(line_out)
                replaced = True
                previous_cache_size = mapping.value
            else:
                dest.write(mapping.original.string)
                missing_newline = not mapping.original.string.endswith("\n")
        if not replaced:
            if missing_newline:
                dest.write("\n")
            dest.write(line_out)

    if replaced:
        click.echo(f"Updated cache size to {value_to_set}MB. (Previously: {previous_cache_size})")
    else:
        click.echo(f"The cache size has been set to {value_to_set}MB.")

    return True, key_to_set, value_to_set
