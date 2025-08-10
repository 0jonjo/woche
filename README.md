# Woche - v1.4.1

Woche is a command-line tool for managing weekly tasks using Bash scripts. It helps you create and organize tasks in Markdown files, with support for English and German day names.

## Features

- Create weekly Markdown files.
- Add, edit, delete, and mark tasks as complete.
- View tasks by week, grouped by day with line numbers.
- Search for tasks across all weeks.
- Open weekly files in your preferred editor.

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

## Customization

- Change file path: Modify `path_to_files` in `variables.sh`.
- Switch to German days: Replace `week_array` with `woche_array` in `variables.sh`.
- Adjust date format: Modify `start_day_of_week` in `functions.sh`.

## License

This project is licensed under the GNU License. See the [LICENSE](LICENSE) file for details.
