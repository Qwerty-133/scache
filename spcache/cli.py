"""A CLI tool to set the Spotify cache size threshold."""

import typing as t

import rich_click as click

# TODO: Inspect the behaviour of the Spotify client when the cache size
# is set to 0.

CACHE_KEY = "storage.size"
CTX_SETTINGS = {"help_option_names": ["-h", "--help"]}

if t.TYPE_CHECKING:
    import dotenv.main


class ExceptionBase(click.ClickException):
    """
    Base class for exceptions raised by this CLI tool.

    Supports reading the message from a class variable.
    """

    exit_code: t.ClassVar[int]
    message: t.ClassVar[str]

    def __init__(self) -> None:
        super().__init__(self.message)


class FileDetectionErrorWithFileOption(ExceptionBase):
    """
    Raised when the Spotify prefs file can't be auto-detected.

    can provide --file option to specify the path to prefs file.
    """

    exit_code = 2
    message = (
        "The Spotify prefs file couldn't be auto-detected."
        "\nPlease specify a path to the prefs file using the --file option."
    )


class FileDetectionError(ExceptionBase):
    """Raised when the Spotify prefs file can't be auto-detected."""

    exit_code = 2
    message = "The Spotify prefs file couldn't be auto-detected."


class EnvInvalidLineError(ExceptionBase):
    """Raised when a line in a .env file is invalid."""

    exit_code = 3
    message = None

    def __init__(self, e: tuple) -> None:
        import textwrap

        line_preview = textwrap.shorten(e.line_content.rstrip(), 80)
        EnvInvalidLineError.message = (
            f"Line {e.line_no} is invalid. ({line_preview})"
            "\nTo ignore this error, use the --force flag."
        )


def handle_file(
    ctx: click.Context, file: t.Optional["dotenv.main.StrPath"], no_prompts: bool
) -> "dotenv.main.StrPath":
    """
    Handle file arguments given to commands.

    If a file is not provided, it is auto-detected. The user is prompted to
    verify the auto-detected file path unless no_prompts is set to True.

    If the file name is not 'prefs', a warning is shown.
    """
    if file is None:
        from spcache import detect

        file = detect.detect_prefs_file()
        if file is None:
            raise FileDetectionErrorWithFileOption

        if not no_prompts:
            click.confirm(
                f"Auto-detected Spotify prefs file: {file}\nIs this correct?",
                abort=True,
            )

    import pathlib

    filepath = pathlib.Path(file)
    if filepath.name != "prefs":
        click.secho(
            f"The given file should be named 'prefs', not '{filepath.name}'. Is the path correct?",
            err=True,
            fg="red",
        )

    return file


@click.group(context_settings=CTX_SETTINGS)
@click.version_option(None, "--version", "-V", package_name=__package__)
def spcache() -> None:
    """Set a limit on the Spotify cache size."""


file_option = click.option(
    "--file",
    "-f",
    default=None,
    help="Path to the Spotify prefs file.",
    type=click.Path(exists=True, dir_okay=False, readable=True, writable=True),
    envvar="SPOTIFY_PREFS_FILE",
    show_envvar=True,
)
yes_option = click.option(
    "--yes",
    "-y",
    is_flag=True,
    help="Do not prompt for confirmation after auto-detecting a path.",
    show_default=True,
    envvar="SPOTIFY_YES",
)
force_option = click.option(
    "--force",
    is_flag=True,
    help="Ignore syntax errors in the prefs file.",
    show_default=True,
    envvar="SPOTIFY_IGNORE_ERRORS",
)


@spcache.command()
@file_option
@click.option(
    "--size",
    "-s",
    default=1024,
    help="Cache limit [MB]",
    type=click.IntRange(0, None),
    show_default=True,
    envvar="SPOTIFY_CACHE_SIZE",
)
@yes_option
@force_option
@click.pass_context
def set(
    ctx: click.Context, file: t.Optional["dotenv.main.StrPath"], size: int, yes: bool, force: bool
) -> None:
    """
    Set the cache size limit on the Spotify prefs file.

    If a file is not specified, it will be auto-detected.
    """
    if ctx.invoked_subcommand is not None:
        return

    file = handle_file(ctx, file, yes)

    from spcache import env

    try:
        previous_value = env.set_key(
            file, CACHE_KEY, str(size), quote_mode="never", ignore_errors=force
        )
    except env.InvalidLineError as e:
        raise EnvInvalidLineError(e) from None

    if previous_value is not None:
        click.secho(
            f"The cache size has been updated from {previous_value} MB to {size} MB.", fg="green"
        )
    else:
        click.secho(f"The cache size has been set to {size} MB.", fg="green")


@spcache.command()
@file_option
@yes_option
@force_option
@click.pass_context
def get(
    ctx: click.Context, file: t.Optional["dotenv.main.StrPath"], yes: bool, force: bool
) -> None:
    """
    Get the current cache size limit from the Spotify prefs file.

    If a file is not specified, it will be auto-detected.
    """
    file = handle_file(ctx, file, yes)

    from spcache import env

    try:
        limit = env.get_key(file, CACHE_KEY, ignore_errors=force)
    except env.InvalidLineError as e:
        raise EnvInvalidLineError(e) from None

    if limit is not None:
        click.secho(f"The cache size is currently {limit} MB.", fg="green")
    else:
        click.secho(
            "The cache size has not been set! Run 'spcache set' to set a limit.", fg="yellow"
        )


@spcache.command()
@click.pass_context
def detect(ctx: click.Context) -> None:
    """Auto-detect the Spotify prefs file."""
    from spcache import detect

    file = detect.detect_prefs_file()
    if file is None:
        raise FileDetectionError

    click.secho(file, fg="green")


if __name__ == "__main__":
    spcache()
