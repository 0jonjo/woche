# Woche

Woche is a collection of Bash scripts that assist in managing weekly tasks. It enables the creation of a new Markdown file for the current week and the addition of tasks to specific days. Woche, meaning 'week' in German, uses German day names (Montag, Dienstag, Mittwoch, Donnerstag, Freitag, Samstag, and Sonntag) for educational purposes. You can choose the name of the days to English.

## Features

- Generates a new Markdown file for the current week, including headers for each day.
- Allows the addition, editing and delete of tasks to a specific day of the week or line of the file.
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

4. **Edit a task of the current week:**

```bash
./woche.sh edit 9 "That task"
```

This command edit the line 9 of Markdown file with the tasks.

5. **Delete a task of the current week:**

```bash
./woche.sh delete 3
```

This command edit the line 3 of Markdown file.

6. **Access instructions:**

```bash
./woche.sh help
```

## Customization Tips
- Change the file creation path by modifying the path variable in the variables.sh file.
- Switch to English day names by replacing woche_array with week_array in the same file.
- Alter the date format of the Markdown file by adjusting the start_day_of_week method in functions.sh.

## Testing

The test.sh script tests the functionality of woche.sh, checking both correct and incorrect user inputs. This test is mandatory for pull requests to the main branch and should be included in the [GitHub Actions](https://github.com/0jonjo/woche/actions) pipeline for automated testing.

To run the tests:

```bash
./test.sh
```
---
## License
This project is licensed under the GNU License. See the [LICENSE](LICENSE) file for details.
