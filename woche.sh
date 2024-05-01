#!/bin/bash

# Path: woche.sh
source $(dirname "$0")/functions.sh
source $(dirname "$0")/variables.sh

cd "$path"

day=""
task="$2"
new_task="$3"
start_day_of_week

# Check the number of arguments
if [ "$#" -gt 3 ]; then
    tips
    exit 1
fi

# Check if $1 is in the options to check
if [[ ! " ${options_to_check[@]} " =~ " $1 " ]]; then
    echo "Invalid command."
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
        file_exists
        printf "Week starts in $start_day.\n\n"
        show_file
        exit 0
        ;;
    help)
        tips
        exit 0
        ;;
    *)
        file_exists
        day=$(eval echo \$$1)
        sed -i "/# $day/ a\\- $task" "$start_day.md"
        echo "Task '$task' added to $day."
        exit 0
        ;;
esac

