# Woche - v1.5.0

Woche is a command-line tool for managing weekly tasks using Bash scripts. It helps you create and organize tasks in Markdown files, with support for English and German day names.

## Features

- Create weekly Markdown files.
- Add, edit, delete, and mark tasks as complete.
- View tasks by week, grouped by day with line numbers.
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

```bash
./woche.sh edit <line_number> "<new_task>"  # Edit a task by line number
./woche.sh delete <line_number>             # Delete a task by line number (requires confirmation)
./woche.sh done <line_number>               # Mark a task as complete
```

### Searching Tasks

```bash
./woche.sh search "<keyword>"  # Search for a keyword in all weekly files
```

### Configuration

```bash
./woche.sh config                  # Show current configuration
./woche.sh config language en      # Set language to English
./woche.sh config language de      # Set language to German
```

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
./test.sh
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
```

### Advanced Customization

- Change file path: Modify `path_to_files` in `variables.sh`.
- Adjust date format: Modify date format strings in `functions.sh`.

## License

This project is licensed under the GNU License. See the [LICENSE](LICENSE) file for details.
