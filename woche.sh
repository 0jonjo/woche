#!/usr/bin/env bash

source functions.sh
source variables.sh

cd "$path_to_files" > /dev/null

day=""
task="$2"
new_task="$3"
current_week
file=$current_week

# Check the number of arguments
if [ "$#" -gt 3 ]; then
    tips
    exit 1
fi

# Check if $1 is in the options to check
if [[ ! " ${options_to_check[@]} " =~ " $1 " ]]; then
    echo "Error: Invalid command."
    tips
    exit 1
fi

case $1 in
    create)
        file_already_exists
        create_file
        exit 0
        ;;
    delete)
        file_exists
        line_exists
        delete_line
        exit 0
        ;;
    edit)
        file_exists
        line_exists
        edit_line
        exit 0
        ;;
    show)
        if [ "$task" ]; then
            file=$task
        fi
        file_exists
        show_file
        exit 0
        ;;
    all)
        show_all_files
        exit 0
        ;;
    help)
        tips
        exit 0
        ;;
    *)
        file_exists
        day=$(eval echo \$$1)
        sed -i "/# $day/ a\\- $task" "$file.md"
        echo "Task '$task' added to $day."
        exit 0
        ;;
esac

