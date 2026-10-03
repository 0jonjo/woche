#!/usr/bin/env bash

# Resolve the library dir from the script's real path, so woche works from
# any directory and through a symlink (/usr/bin/woche -> /usr/lib/woche/woche.sh)
woche_lib=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

# shellcheck source=functions.sh
source "$woche_lib/functions.sh"
# shellcheck source=variables.sh
source "$woche_lib/variables.sh"
load_config

day=""
task="$2"
export new_task="$3"

if [ "$#" -eq 0 ]; then
    help
    exit 0
fi

# Check the number of arguments
if [ "$#" -gt 4 ]; then
    help
    exit 1
fi

if ! valid_command "$1"; then
    echo "Error: Invalid command."
    help
    exit 1
fi

# Commands that don't touch the weekly files
case $1 in
    help)
        help
        exit 0
        ;;
    --version)
        echo "woche $WOCHE_VERSION"
        exit 0
        ;;
    init)
        woche_init
        exit 0
        ;;
    config)
        if [ -z "$task" ]; then
            show_config
        elif [ "$task" = "language" ]; then
            if [ -z "$new_task" ]; then
                echo "Error: Please specify language (en or de)."
                echo "Usage: woche.sh config language <en|de>"
                exit 1
            fi
            set_language "$new_task"
        elif [ "$task" = "dir" ]; then
            if [ -z "$new_task" ]; then
                echo "Error: Please specify a directory."
                echo "Usage: woche.sh config dir <path>"
                exit 1
            fi
            set_dir "$new_task"
        else
            echo "Error: Unknown config option '$task'."
            echo "Usage: woche.sh config [language <en|de> | dir <path>]"
            exit 1
        fi
        exit 0
        ;;
esac

first_run_setup
missing_dir_hint

mkdir -p -- "$WOCHE_DIR" && cd -- "$WOCHE_DIR" > /dev/null || exit 1

current_week
last_week
export file=$current_week

case $1 in
    create)
        file_already_exists
        create_file
        exit 0
        ;;
    delete)
        file_exists
        resolve_task "$2" "$3"
        delete_task
        exit 0
        ;;
    edit)
        file_exists
        resolve_task "$2" "$3" "$4"
        edit_task
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
        resolve_task "$2" "$3"
        mark_task_done
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
