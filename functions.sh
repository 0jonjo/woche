#!/usr/bin/env bash

tips() {
    echo "tips: woche.sh"
    echo "create: a new markdown file for the current week"
    echo "${week_array_string[@]}: to add a task to the day of the week."
    echo "show: show the tasks for the current week"
    echo "delete X: delete a task from the current week - X is the line number"
    echo "edit X: edit a task from the current week - X is the line number"
    echo "all: show all markdown files in the current directory"
}

start_day_of_week() {
    start_day=$(date -d "last monday" "+%y%m%d")

    if [ "$(date "+%u")" == 1 ]; then
        start_day=$(date "+%y%m%d")
    fi

    start_day_formatted=$(date -d "$start_day" "+%d/%m/%Y")
}

file_exists() {
    if [ ! -e "$start_day.md" ]; then
        echo "Error: The file $start_day.md does not exist."
        exit 1
    fi
}

file_already_exists() {
    if [ -e "$start_day.md" ]; then
        echo "Error: The file $start_day.md already exists."
        exit 1
    fi
}

line_exists() {
    if [ -z "$(sed -n "${task}p" "$start_day.md")" ]; then
        echo "Error: Line $task does not exist."
        exit 1
    fi
}

create_file() {
    for i in "${week_array[@]}"; do
        printf "# %s\n\n" "$i" >> "$start_day.md"
    done
    echo "The file $start_day.md has been created."
}

delete_line() {
    sed -i "${task}d" "$start_day.md"
    echo "Line ${task} deleted."
}

edit_line() {
    sed -i "${task}s/.*/- $new_task/" "$start_day.md"
    echo "Line ${task} edited."
}

show_file() {
    cat -n "$start_day.md"
}

show_all_files() {
    echo "All markdown files in $path_to_files:"
    ls -1 *.md
}
