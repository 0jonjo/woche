#!/bin/bash

#Path: functions.sh

tips() {
    echo "tips: woche.sh"
    echo "create: a new markdown file for the current week"
    echo "${woche_array_string[@]}: to add a task to the day of the week."
}

start_day_of_week() {
    start_day=$(date -d "last monday" "+%y%m%d")

    if [ "$(date "+%u")" == 1 ]; then
        start_day=$(date "+%y%m%d")
    fi
}

file_exists() {
    if [ ! -e "$start_day.md" ]; then
        echo "The file $start_day.md does not exist."
        exit 1
    fi
}

file_already_exists() {
    if [ -e "$start_day.md" ]; then
        echo "The file $start_day.md already exists."
        exit 1
    fi
}

line_exists() {
    if [ -z "$(sed -n "${task}p" "$start_day.md")" ]; then
        echo "Line $task does not exist."
        exit 1
    fi
}

create_file() {
    for i in "${woche_array[@]}"; do
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
