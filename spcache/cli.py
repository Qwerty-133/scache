"""A CLI tool to set the Spotify cache size threshold."""

import typing as t

import click

# TODO: Inspect the behaviour of the Spotify client when the cache size
# is set to 0.

CACHE_KEY = "storage.size"
CTX_SETTINGS = {"help_option_names": ["-h", "--help"]}


@click.group(context_settings=CTX_SETTINGS, invoke_without_command=True)
@click.option(
    "--file",
    "-f",
    default=None,
    help="Path to the Spotify prefs file.",
    type=click.Path(exists=True, dir_okay=False, readable=True, writable=True),
    envvar="SPOTIFY_PREFS_FILE",
    show_envvar=True,
)
@click.option(
    "--size",
    "-s",
    default=1024,
    help="Cache limit [MB]",
    type=click.IntRange(0, None),
    show_default=True,
    envvar="SPOTIFY_CACHE_SIZE",
)
@click.option(
    "--yes",
    "-y",
    is_flag=True,
    help="Do not prompt for confirmation after auto-detecting a path.",
    show_default=True,
    envvar="SPOTIFY_YES",
)
@click.option(
    "--force",
    is_flag=True,
    help="Ignore syntax errors in the prefs file.",
    show_default=True,
    envvar="SPOTIFY_IGNORE_ERRORS",
)
@click.version_option(None, "--version", "-V", package_name=__package__)
@click.pass_context
def spcache(ctx: click.Context, file: t.Optional[str], size: int, yes: bool, force: bool) -> None:
    """
    Set the cache size limit on the Spotify prefs file.

    If a file is not specified, it will be auto-detected.
    """
    if ctx.invoked_subcommand is not None:
        return

    if file is None:
        from spcache import detect

        file = detect.detect_prefs_file()
        if file is None:
            click.echo(
                "The Spotify prefs file couldn't be auto-detected."
                "\nPlease specify a path to the prefs file using the --file option.",
                err=True,
            )
            ctx.exit(2)

        if not yes:
            click.confirm(
                f"Auto-detected Spotify prefs file: {file}\nIs this correct?",
                abort=True,
            )

    import pathlib

    filepath = pathlib.Path(file)
    if filepath.name != "prefs":
        click.echo(
            f"The given file should be named 'prefs', not '{filepath.name}'. Is the path correct?",
            err=True,
        )

    from spcache import env

    try:
        previous_value = env.set_key(
            file, CACHE_KEY, str(size), quote_mode="never", ignore_errors=force
        )
    except env.InvalidLineError as e:
        import textwrap

        line_preview = textwrap.shorten(e.line_content.rstrip(), 80)
        click.echo(
            f"Line {e.line_no} is invalid. ({line_preview})"
            "\nTo ignore this error, use the --force flag.",
            err=True,
        )
        ctx.exit(3)

    if previous_value is not None:
        click.echo(f"The cache size has been updated from {previous_value} to {size} MB.")
    else:
        click.echo(f"The cache size has been set to {size} MB.")


@spcache.command()
@click.pass_context
def detect(ctx: click.Context) -> None:
    """Auto-detect the Spotify prefs file."""
    from spcache import detect

    file = detect.detect_prefs_file()
    if file is None:
        click.echo("The Spotify prefs file couldn't be auto-detected.", err=True)
        ctx.exit(2)

    click.echo(file)


if __name__ == "__main__":
    spcache()
