# Woche

Woche is a program that assists in managing weekly tasks. It uses Bash scripts to enable the creation of a new Markdown file for the current week and the addition of tasks to specific days. It can navigate in the tasks of another weeks too. The word "Woche" means 'week' in German. You can choose between options with the names of the days in English or German.

## Features

- Generates a new Markdown file for the current week, including headers for each day.
- Allows the addition, editing and delete of tasks to a specific day of the week or line of the file.
- Lists and shows the tasks of the different weeks.
- Provides usage tips.

## Usage

**Create a new Markdown file for the current week (starting on Monday):**

```bash
./woche.sh create
```

This command creates a file using the YYMMDD format.

**Add a task to a specific day:**

```bash
./woche.sh <day> "<task>"
```

Replace <day> with the day of the week and <task> with the task description. The days in German are: mont, die, mit, don, frei, sam and son, in English: mon, tue, wed, thu, fri, sat and sun.

**Display the tasks of the current week:**

```bash
./woche.sh show
```

This command prints the Markdown file with the tasks for the entire week.

**Edit a task of the current week:**

```bash
./woche.sh edit 9 "That task"
```

This command edit the line 9 of Markdown file with the tasks.

**Delete a task of the current week:**

```bash
./woche.sh delete 3
```

This command edit the line 3 of Markdown file.

**List the files of the different weeks:**

```bash
./woche.sh all
```

***Show the tasks of a specific week:**

```bash
./woche.sh show 210829
```

**Access instructions:**

```bash
./woche.sh help
```

## Testing

The test.sh script tests the functionality of woche.sh, checking both correct and incorrect user inputs. This test is mandatory for pull requests to the main branch and should be included in the [GitHub Actions](https://github.com/0jonjo/woche/actions) pipeline for automated testing.

To run the tests:

```bash
./test.sh
```

## Docker

To use the dockerized version of Woche, follow these instructions:

```bash
# Build the image
docker build -t woche-app .

# Run the container
docker run -it woche-app
```

## Customization Tips

- Change the file creation path by modifying the path variable in the variables.sh file.
- Switch to German day names by replacing week_array with woche_array in the same file.
- Alter the date format of the Markdown file by adjusting the start_day_of_week method in functions.sh.
- Use dockerized version if not in Ubuntu/Debian like system operation.

---

## License

This project is licensed under the GNU License. See the [LICENSE](LICENSE) file for details.
