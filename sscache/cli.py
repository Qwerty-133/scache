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
@click.version_option(None, "--version", "-V", package_name=__package__)
def sscache(file: str, size: int) -> None:
    """
    Set the cache size limit on the Spotify prefs file: FILE.

    FILE is the path to the Spotify prefs file.
    FILE may also be specified through the SPOTIFY_PREFS_FILE
    environment variable.
    """
    import dotenv

    dotenv.set_key(file, CACHE_KEY, str(size), quote_mode="never")
    click.echo(f"Updated cache size to {size}MB.")


if __name__ == "__main__":
    sscache()
