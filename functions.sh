#!/usr/bin/env bash

tips() {
    echo "tips: woche.sh"
    echo "create: a new markdown file for the current week"
    echo "${week_array_string[@]}: to add a task to the day of the week."
    echo "show: show the tasks for the current week"
    echo "show YYMMDD: show the tasks for the week starting on YYMMDD"
    echo "show last: show the tasks for last week"
    echo "delete X: delete a task from the current week - X is the line number"
    echo "edit X: edit a task from the current week - X is the line number"
    echo "all: show all markdown files in the current directory"
}

current_week() {
    current_week=$(date -d "last monday" "+%y%m%d")

    if [ "$(date "+%u")" == 1 ]; then
        current_week=$(date "+%y%m%d")
    fi
}

last_week() {
    last_week=$(date -d "$current_week - 7 days" "+%y%m%d")
}

file_exists() {
    if [ ! -e "$file.md" ]; then
        echo "Error: The file $file.md does not exist."
        exit 1
    fi
}

file_already_exists() {
    if [ -e "$file.md" ]; then
        echo "Error: The file $file.md already exists."
        exit 1
    fi
}

line_exists() {
    if [ -z "$(sed -n "${task}p" "$file.md")" ]; then
        echo "Error: Line $task does not exist."
        exit 1
    fi
}

create_file() {
    create_week
    echo "The file $file.md has been created."
}

create_week() {
    day_of_month=$(date -d "$current_week" "+%d" | sed 's/^0*//')
    counter=0
    days_of_month=$(( $(date -d "$(date -d "$current_week" "+%Y-%m-01") +1 month -1 day" "+%d") ))
    current_month=$(( $(date -d "$current_week" "+%m") ))
    month=$current_month
    for i in "${week_array[@]}"; do
        day_sum=$((day_of_month + counter))
        if [ $day_sum -gt $days_of_month ]; then
            day_sum=$((day_sum - days_of_month))
            month=$((current_month + 1))
        fi
        printf "# %s\n\n" "$i, $day_sum/$month" >> "$file.md"
        ((counter++))
    done
}

delete_line() {
    sed -i "${task}d" "$file.md"
    echo "Line ${task} deleted."
}

edit_line() {
    escaped_task=$(sed 's/[\/&]/\\&/g' <<< "$new_task")
    sed -i "${task}s/.*/- $escaped_task/" "$file.md"
    echo "Line ${task} edited."
}

show_file() {
    start_day_formatted=$(date -d "$file" "+%d/%m/%Y")
    printf "Week starts on %s.\n\n" "$start_day_formatted"
    cat -n "$file.md"
}

show_all_files() {
    echo "All markdown files in $path_to_files:"
    ls -1 *.md
}
