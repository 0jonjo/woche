#!/usr/bin/env bash

source functions.sh
source variables.sh

cd "$path_to_files" > /dev/null || exit

day=""
task="$2"
export new_task="$3"
current_week
last_week
export file=$current_week

# Check the number of arguments
if [ "$#" -gt 3 ]; then
    help
    exit 1
fi

# Check if $1 is in the options to check
if [[ ! " ${options_to_check[@]} " =~ $1 ]]; then
    echo "Error: Invalid command."
    help
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
        if [ "$task" = "last" ]; then
            export file=$last_week
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
        help
        exit 0
        ;;
    today)
        file_exists
        day_of_week=$(date +%u)
        day=${week_array[$((day_of_week-1))]}
        add_task "$day" "$task"
        exit 0
        ;;
    search)
        search_files "$task"
        exit 0
        ;;
    done)
        file_exists
        line_exists
        mark_task_done "$task"
        exit 0
        ;;
    open)
        file_exists
        open_file_in_editor
        exit 0
        ;;
    *)
        file_exists
        day_abbr=$1
        day_full=""
        # Find the full day name from the abbreviation
        for i in "${!week_array_string[@]}"; do
           if [[ "${week_array_string[$i]}" = "$day_abbr" ]]; then
               day_full="${week_array[$i]}"
               break
           fi
        done

        if [ -z "$day_full" ]; then
            echo "Error: Invalid day '$1'."
            help
            exit 1
        fi

        add_task "$day_full" "$task"
        exit 0
        ;;
esac