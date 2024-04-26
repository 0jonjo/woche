# Woche

Woche is a collection of Bash scripts that assist in managing weekly tasks. It enables the creation of a new Markdown file for the current week and the addition of tasks to specific days. Woche, meaning 'week' in German, uses German day names (Montag, Dienstag, Mittwoch, Donnerstag, Freitag, Samstag, and Sonntag) for educational purposes.

## Features

- Generates a new Markdown file for the current week, including headers for each day.
- Allows the addition of tasks to a specific day of the week.
- Provides usage tips.

## Usage

1. **Create a new Markdown file for the current week (starting on Monday):**

```bash
./woche.sh create
```
This command creates a file using the YYMMDD format.

2. **Add a task to a specific day:**

```bash
./woche.sh <day> "<task>"
```

Replace <day> with the day of the week (in German: mon, die, mit, don, frei, sam, son) and <task> with the task description.

3. **Display the tasks of the current week:**

```bash
./woche.sh show
```

This command prints the Markdown file with the tasks for the entire week.

**4. Access instructions:**

```bash
./woche.sh help
```

## Customization Tips
- Change the file creation path by modifying the path variable in the woche.sh file.
- Alter the date format in the Markdown file by adjusting the start_day.
- Switch to English day names by replacing woche_array with week_array.

## Testing

The test.sh script tests the functionality of woche.sh, checking both correct and incorrect user inputs. This test is mandatory for pull requests to the main branch and should be included in the [GitHub Actions](https://github.com/0jonjo/woche/actions) pipeline for automated testing.

To run the tests:

```bash
./test.sh
```
---
## License
This project is licensed under the GNU License. See the [LICENSE](LICENSE) file for details.
