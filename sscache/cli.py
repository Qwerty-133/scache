"""A CLI tool to set the Spotify cache size threshold."""

import click

# TODO: Inspect the behaviour of the Spotify client when the cache size
# is set to 0.

CACHE_KEY = "storage.size"
CTX_SETTINGS = {"help_option_names": ["-h", "--help"]}


@click.command(context_settings=CTX_SETTINGS)
@click.argument(
    "file",
    type=click.Path(exists=True, dir_okay=False, readable=True, writable=True),
    envvar="SPOTIFY_PREFS_FILE",
)
@click.option(
    "--size",
    "-s",
    default=1024,
    help="Cache limit [MB]",
    type=click.IntRange(0, None),
    show_default=True,
    envvar="SPOTIFY_CACHE_SIZE",
    show_envvar=True,
)
@click.option(
    "--force",
    "-f",
    is_flag=True,
    help="Ignore errors in the prefs file.",
    show_default=True,
    envvar="SPOTIFY_IGNORE_ERRORS",
    show_envvar=True,
)
@click.version_option(None, "--version", "-V", package_name=__package__)
@click.pass_context
def sscache(ctx: click.Context, file: str, size: int, force: bool) -> None:
    """
    Set the cache size limit on the Spotify prefs file: FILE.

    FILE is the path to the Spotify prefs file.
    FILE may also be specified through the SPOTIFY_PREFS_FILE
    environment variable.
    """
    from sscache import env

    env.set_cache_size(ctx, file, CACHE_KEY, str(size), quote_mode="never", force=force)


if __name__ == "__main__":
    sscache()
