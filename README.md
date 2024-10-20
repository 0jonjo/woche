# Woche

Woche is a tool for managing weekly tasks using Bash scripts. It creates a new Markdown file for the current week and allows you to add tasks to specific days. "Woche" means 'week' in German, and you can choose between English or German day names.

## Features

- Generates a new Markdown file for the current week with headers for each day.
- Allows adding, editing, and deleting tasks for specific days or lines.
- Lists and displays tasks from different weeks.
- Provides usage tips.

## Usage

### Create a New Markdown File for the Current Week

```bash
./woche.sh create
# The file 241014.md has been created
```

This command creates a file using the YYMMDD format.

### Add a Task to a Specific Day

```bash
./woche.sh <day> "<task>"
```

Replace `<day>` with the day of the week and `<task>` with the task description. Days in English: mon, tue, wed, thu, fri, sat, sun. Days in German: mont, die, mit, don, frei, sam, son.

```bash
./woche.sh mon "Do something"
# Do something was added to Monday.
```

### Display Tasks of the Current Week

```bash
./woche.sh show
```

### Edit a Task of the Current Week

```bash
./woche.sh edit 9 "That task"
# Line 9 edited.
```

### Delete a Task of the Current Week

```bash
./woche.sh delete 3
# Line 3 deleted.
```

### List Files of Different Weeks

```bash
./woche.sh all
```

### Display Tasks of Last Week

```bash
./woche.sh show last
```

### Show Tasks of a Specific Week

```bash
./woche.sh show 210829
```

### Access Instructions

```bash
./woche.sh help
```

## Testing

The `test.sh` script tests the functionality of `woche.sh`, checking both correct and incorrect user inputs. This test is mandatory for pull requests to the main branch and should be included in the [GitHub Actions](https://github.com/0jonjo/woche/actions) pipeline for automated testing.

To run the tests:

```bash
./test.sh
```

## Docker

To use the Dockerized version of Woche:

```bash
# Build the image
docker build -t woche-app .

# Run the container
docker run -it woche-app
```

## Customization Tips

- Change the file creation path by modifying the `path` variable in `variables.sh`.
- Switch to German day names by replacing `week_array` with `woche_array` in `variables.sh`.
- Alter the date format of the Markdown file by adjusting the `start_day_of_week` method in `functions.sh`.
- Use the Dockerized version if not on an Ubuntu/Debian system.

## License

This project is licensed under the GNU License. See the [LICENSE](LICENSE) file for details.
