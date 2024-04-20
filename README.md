# Woche

Woche is a collection of Bash scripts designed to help manage weekly tasks. It allows you to create a new Markdown file for the current week and add tasks to specific days. Woche means week in German, the days of the week are represented in German (Montag, Dienstag, Mittwoch, Donnerstag, Freitag, Samstag, Sonntag) only for study the language.

## Features

- Create a new Markdown file for the current week with headers for each day of the week.
- Add tasks to a specific day of the week.
- Display usage tips.

## Usage

To create a new Markdown file for the current week (starts in Monday):

```bash
./woche.sh create

Output:
The file 240422.md has been created.
```
It uses the YYMMDD format.

To add a task to a specific day:

```bash
./woche.sh <day> "<task>"
```

Replace `<day>` with the day of the week (in German: mon, die, mit, don, frei, sam, son) and `<task>` with the task description. Example:

```bash
./woche.sh mon "Test"

Output:
Task added to Montag.
```
To obtain instructions use help.

```bash
./woche.sh help
```

### Tips
- To change de path where the files are created changing the path variable in `woche.sh` file.
- To change the format of date in the Markdown file change start_day in line 21.
- To use the name of the days in English, change the woche_array for week_array in line 53.

## Testing

The `test.sh` script is used to test the functionality of `woche.sh`. It tests the 'help', 'create', and 'add task' commands, and checks if the script handles more than 2 arguments correctly.

To run the tests:

```bash
./test.sh
```
---

License
This project is licensed under the GNU License. See the [LICENSE](LICENSE) file for details.
