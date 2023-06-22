<!-- markdownlint-disable-next-line first-line-heading -->
<div align="center">
  <h1>spcache</h1>
  A simple CLI tool to set a limit on Spotify's cache size.
</div>

<p align="center">
  <a href="LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/Qwerty-133/spcache">
  </a>
  <a href="https://github.com/Qwerty-133/spcache/releases/latest">
    <img alt="Release" src="https://img.shields.io/github/v/release/Qwerty-133/spcache">
  </a>
  <a href="https://pypi.org/project/spcache/">
    <img alt="PyPI" src="https://img.shields.io/pypi/v/spcache">
  </a>
</p>

## Installation

> See [Installing a Specific Version](#installing-a-specific-version) for additional options.

### Windows

> Open PowerShell. You can do this by searching for "PowerShell" in the Start menu.

Paste the following and hit enter:

```powershell
Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/Qwerty-133/spcache/main/bin/install_spcache.ps1 |
  Invoke-Expression
```

### MacOS/Linux

```bash
curl -sSL https://raw.githubusercontent.com/Qwerty-133/spcache/main/bin/install_spcache.sh | bash -s -
```

## Usage

-   Set the cache size to 1GB:

    ```bash
    spcache set --size 1000
    ```

    spcache will try to detect your Spotify prefs file and set the cache size to the specified value in megabytes (MB).

-   Specify the path to your prefs file manually:

    ```bash
    spcache set --size 1000 --file /path/to/prefs
    ```

-   View more options:

    ```bash
    spcache --help
    ```

## Uninstallation

### Windows

```powershell
Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/Qwerty-133/spcache/main/bin/uninstall_spcache.ps1 |
  Invoke-Expression
```

This will remove the spcache files and remove spcache from your PATH.

### MacOS/Linux

spcache is installed in `~/.local/share/spcache`, unless `$XDG_DATA_HOME` is set.

```bash
rm -r "~/.local/share/spcache" || rm -r "${XDG_DATA_HOME}/spcache"
```

## Installing a Specific Version

> Available versions are listed here <https://github.com/Qwerty-133/spcache/releases>.

### Windows

Installing a specific version of spcache:

```powershell
$script = [scriptblock]::Create(
  (iwr -useb "https://raw.githubusercontent.com/Qwerty-133/spcache/main/bin/install_spcache.ps1").Content
)
& $script -Version 0.1.0
```

### MacOS/Linux

Installing a specific version of spcache:

```bash
curl -sSL https://raw.githubusercontent.com/Qwerty-133/spcache/main/bin/install_spcache.sh |
  bash -s - --version 0.1.0
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
