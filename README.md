# Woche - v1.5.0

Woche is a command-line tool for managing weekly tasks using Bash scripts. It helps you create and organize tasks in Markdown files, with support for English and German day names.

## Features

- Create weekly Markdown files.
- Add, edit, delete, and mark tasks as complete.
- View tasks by week, grouped by day, each with a short address (`mon.2`).
- Search for tasks across all weeks.
- Open weekly files in your preferred editor.
- Configure language preference (English or German).
- Automatic language detection for displaying existing files.

## Usage

### Getting Started

```bash
./woche.sh create
# Creates a new Markdown file for the current week (e.g., 241014.md)
```

### Adding Tasks

```bash
./woche.sh <day> "<task>"      # Add task to a specific day (e.g., mon, tue, mont, die)
./woche.sh today "<task>"      # Add task to the current day
```

### Viewing Tasks

```bash
./woche.sh show                # Display tasks for the current week
./woche.sh show last          # Display tasks for last week
./woche.sh show <YYMMDD>      # Display tasks for a specific week (e.g., 210829)
./woche.sh all                 # List all weekly Markdown files
```

### Managing Tasks

`show` prints an address next to each task: `mon.2` is the second task on Monday.

```bash
./woche.sh done mon 2                 # Mark a task as complete
./woche.sh edit mon 2 "<new_task>"    # Edit a task (a finished task stays finished)
./woche.sh delete mon 2               # Delete a task (requires confirmation)
```

`mon.2` works as well, and so does a plain line number of the file (the addressing of older versions).

To work on another week, set `WOCHE_WEEK` to its Monday:

```bash
WOCHE_WEEK=260921 ./woche.sh create
WOCHE_WEEK=260921 ./woche.sh fri "Filled in later"
```

### Searching Tasks

```bash
./woche.sh search "<keyword>"  # Search for a keyword in all weekly files
```

### Configuration

On the first interactive run, woche asks for the language and the directory for your weekly files (default: `~/woche`) and saves them to `~/.woche/config`. Scripts and cron jobs (no terminal) just use the defaults.

```bash
./woche.sh init                    # Set up language and directory again
./woche.sh config                  # Show current configuration
./woche.sh config language en      # Set language to English
./woche.sh config language de      # Set language to German
./woche.sh config dir ~/notes      # Store weekly files in ~/notes (existing files are not moved)
./woche.sh --version               # Show the version
```

The environment variables `WOCHE_DIR` and `WOCHE_LANGUAGE` override the config file.

**Note:** Language setting applies to new files created after the change. Existing files will continue to be displayed correctly regardless of the language setting, thanks to automatic language detection.

**Day commands:**
- English: `mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun`
- German: `mont`, `die`, `mit`, `don`, `fre`, `sam`, `son`

### Other Commands

```bash
./woche.sh open                # Open the current week's file in $EDITOR
./woche.sh help                # Display all commands and usage
```

## Testing

To run the test suite:

```bash
./tests.sh
```

## Docker

To use the Dockerized version:

```bash
docker build -t woche-app .  # Build the image
docker run -it woche-app     # Run the container
```

## Configuration

Woche stores configuration in `~/.woche/config`. You can manage settings using the `config` command:

```bash
# View current configuration
./woche.sh config

# Change language (applies to new files)
./woche.sh config language en  # English
./woche.sh config language de  # German
```

### Manual Configuration

You can also edit `~/.woche/config` directly:

```bash
# Language for day names: en (English) or de (German)
WOCHE_LANGUAGE="en"
# Directory where the weekly files are stored
WOCHE_DIR="/home/you/woche"
```

### Advanced Customization

- Change file path: `./woche.sh config dir <path>` or set `WOCHE_DIR`.
- Adjust date format: Modify date format strings in `functions.sh`.

## License

This project is licensed under the GNU License. See the [LICENSE](LICENSE) file for details.
