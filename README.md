# Woche - v1.6.0

Woche is a command-line tool for managing weekly tasks using Bash scripts. It helps you create and organize tasks in Markdown files, with support for English and German day names.

## Features

- Create weekly Markdown files.
- Add, edit, delete, and mark tasks as complete.
- View tasks by week, grouped by day, each with a short address (`mon.2`).
- Search for tasks across all weeks.
- Open weekly files in your preferred editor.
- Configure language preference (English or German) and where the files live.
- Automatic language detection for displaying existing files.
- Bash completion and a man page.

## Getting Started

### Install

On Debian/Ubuntu, download the `.deb` from the [latest release](https://github.com/0jonjo/woche/releases/latest) and install it:

```bash
sudo apt install ./woche_1.6.0_all.deb
```

From a checkout (any Linux with GNU coreutils):

```bash
sudo make install                  # into /usr/local
make install PREFIX=~/.local       # or just for you
```

`make uninstall` (with the same `PREFIX`) removes it. You can also run `./woche.sh` straight from the checkout.

### First run

```bash
woche create
```

The first time you use woche in a terminal, it asks for the language of the day names and the directory for your weekly files (default: `~/woche`), saves them to `~/.woche/config` and goes on to create the file for the current week (e.g., `261005.md`). Scripts and cron jobs (no terminal) just use the defaults.

## Usage

### Adding Tasks

```bash
woche <day> "<task>"      # Add a task to the end of a day (e.g., mon, tue, mont, die)
woche today "<task>"      # Add a task to the current day
```

**Day commands:**
- English: `mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun`
- German: `mont`, `die`, `mit`, `don`, `fre`, `sam`, `son`

### Viewing Tasks

```bash
woche show                # Display tasks for the current week
woche show last           # Display tasks for last week
woche show <YYMMDD>       # Display tasks for a specific week (e.g., 260921)
woche all                 # List all weekly files
```

### Managing Tasks

`show` prints an address next to each task: `mon.2` is the second task on Monday.

```bash
woche done mon 2                 # Mark a task as complete
woche edit mon 2 "<new_task>"    # Edit a task (a finished task stays finished)
woche delete mon 2               # Delete a task (requires confirmation)
```

`mon.2` works as well, and so does a plain line number of the file (the addressing of older versions).

To work on another week, set `WOCHE_WEEK` to its Monday:

```bash
WOCHE_WEEK=260921 woche create
WOCHE_WEEK=260921 woche fri "Filled in later"
```

### Searching Tasks

```bash
woche search "<text>"     # Search for a literal text in all weekly files
```

### Other Commands

```bash
woche open                # Open the current week's file in $EDITOR
woche help                # Display all commands and usage
woche --version           # Show the version
man woche                 # The manual
```

## Configuration

```bash
woche init                    # Set up language and directory again
woche config                  # Show current configuration
woche config language en      # Set language to English
woche config language de      # Set language to German
woche config dir ~/notes      # Store weekly files in ~/notes (existing files are not moved)
```

The language setting applies to new files. Existing files keep being displayed correctly, thanks to automatic language detection.

The environment variables `WOCHE_DIR` and `WOCHE_LANGUAGE` override the config file.

You can also edit `~/.woche/config` directly:

```bash
# Language for day names: en (English) or de (German)
WOCHE_LANGUAGE="en"
# Directory where the weekly files are stored
WOCHE_DIR="/home/you/woche"
```

### Upgrading from 1.5

1.5 kept the directory in `variables.sh`. Tell woche where your files are once:

```bash
woche config dir <directory-of-your-weekly-files>
```

## Development

```bash
make test                 # Run the test suite
make lint                 # shellcheck
make deb                  # Build the .deb into dist/ (needs nfpm)
```

Pushing a `v*` tag builds the `.deb` and attaches it to the GitHub release.

## License

This project is licensed under the GNU General Public License v3. See the [LICENSE](LICENSE) file for details.
