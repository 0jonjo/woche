#!/usr/bin/env bash

help() {
    cat << EOF
Woche - Weekly Task Manager

USAGE:
    woche.sh <command> [arguments]

COMMANDS:
    create                      Create a new markdown file for the current week
    <day> "<task>"              Add a task to a specific day
                                Days: mon, tue, wed, thu, fri, sat, sun
                                (or mont, die, mit, don, fre, sam, son for German)
    today "<task>"              Add a task to the current day

    show [YYMMDD|last]          Show tasks for current week, specific week, or last week
    all                         List all markdown files in the current directory

    edit <line> "<new_task>"    Edit a task by line number
    delete <line>               Delete a task by line number (requires confirmation)
    done <line>                 Mark a task as complete

    search "<keyword>"          Search for a keyword in all weekly files
    open                        Open the current week's file in \$EDITOR

    config                      Show current configuration
    config language <en|de>     Set language for day names (applies to new files only)

    help                        Show this help message

EXAMPLES:
    woche.sh create
    woche.sh mon "Team meeting at 10am"
    woche.sh today "Review pull requests"
    woche.sh show 260203
    woche.sh done 5
    woche.sh search "meeting"
    woche.sh config
    woche.sh config language de

For more information, visit: https://github.com/0jonjo/woche
EOF
}

current_week() {
    current_week=$(date -d "last monday" "+%y%m%d")

    if [ "$(date "+%u")" == 1 ]; then
        current_week=$(date "+%y%m%d")
    fi
}

last_week() {
    last_week=$(date -d "$current_week - 7 days" "+%y%m%d")
    export last_week
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
    day_of_month=$(date -d "$current_week" "+%-d")
    counter=0
    days_of_month=$(( $(date -d "$(date -d "$current_week" "+%Y-%m-01") +1 month -1 day" "+%d") ))
    current_month=$(date -d "$current_week" "+%-m")
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
    read -p "Are you sure you want to delete line ${task}? (y/N): " confirm
    if [[ "$confirm" =~ ^[yY]$ ]]; then
        sed -i "${task}d" "$file.md"
        echo "Line ${task} deleted."
    else
        echo "Deletion cancelled."
    fi
}

edit_line() {
    escaped_task=$(sed 's/[\/&]/\\&/g' <<< "$new_task")
    sed -i "${task}s/.*/- $escaped_task/" "$file.md"
    echo "Line ${task} edited."
}

detect_file_language() {
    local file_path="$1"

    # Check if file has German day names
    if grep -q "^# Montag," "$file_path" || \
       grep -q "^# Dienstag," "$file_path" || \
       grep -q "^# Mittwoch," "$file_path"; then
        echo "de"
        return
    fi

    # Check if file has English day names
    if grep -q "^# Monday," "$file_path" || \
       grep -q "^# Tuesday," "$file_path" || \
       grep -q "^# Wednesday," "$file_path"; then
        echo "en"
        return
    fi

    # Default to current config
    echo "${WOCHE_LANGUAGE:-en}"
}

show_file() {
    # Detect file language
    local file_lang
    file_lang=$(detect_file_language "$file.md")

    # Use appropriate day arrays based on file language
    local -a display_week_array
    if [ "$file_lang" = "de" ]; then
        display_week_array=("${woche_array[@]}")
    else
        display_week_array=("Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
    fi

    start_day_formatted=$(date -d "$file" "+%d/%m/%Y")
    printf "Week starts on %s.\n\n" "$start_day_formatted"

    legend_string=""
    for day_full_name in "${display_week_array[@]}"; do
        header_line=$(grep "^# ${day_full_name}," "$file.md")
        if [ -n "$header_line" ]; then
            date_part=$(echo "$header_line" | awk -F', ' '{print $2}' | awk '{print $1}')
            day_abbr=$(echo "$day_full_name" | cut -c1-3 | tr '[:upper:]' '[:lower:]')
            if [ -n "$legend_string" ]; then
                legend_string+=", "
            fi
            legend_string+="${day_abbr} (${date_part})"
        fi
    done
    printf "Current week: %s\n\n" "$legend_string"

    awk_output=$(awk '
    /^# / {
        current_day = substr($0, 3);
        sub(/,.*$/, "", current_day);
        next;
    }
    /^- / {
        print current_day "::" $0 " (" NR ")";
    }
    ' "$file.md")

    for ordered_day in "${display_week_array[@]}"; do
        day_tasks=$(echo "$awk_output" | grep "^${ordered_day}::")

        if [ -n "$day_tasks" ]; then
            printf "%s:\n" "$ordered_day"
            echo "$day_tasks" | sed 's/^[^:]*:://'
            printf "\\n"
        fi
    done
}

show_all_files() {
    echo "All markdown files in $path_to_files:"
    ls -1 ./*.md
}

add_task() {
    local day_name="$1"
    local task_text="$2"

    # Check if the day header exists in the file
    if ! grep -q "^# $day_name," "$file.md"; then
        # Detect file language
        local file_lang
        file_lang=$(detect_file_language "$file.md")

        # Provide helpful error message
        if [ "$file_lang" = "en" ] && [ "$WOCHE_LANGUAGE" = "de" ]; then
            echo "Error: This file uses English day names, but you're using German commands."
            echo "Use English commands (mon, tue, wed, etc.) or create a new file with: woche.sh create"
            exit 1
        elif [ "$file_lang" = "de" ] && [ "$WOCHE_LANGUAGE" = "en" ]; then
            echo "Error: This file uses German day names, but you're using English commands."
            echo "Use German commands (mont, die, mit, etc.) or create a new file with: woche.sh create"
            exit 1
        else
            echo "Error: Day header '# $day_name' not found in $file.md"
            exit 1
        fi
    fi

    escaped_task=$(sed 's/[\/&]/\\&/g' <<< "$task_text")
    sed -i "/# $day_name/ a\\- $escaped_task" "$file.md"
    echo "Task '$task_text' added to $day_name."
}

search_files() {
    search_term="$1"
    echo "Searching for '$search_term' in markdown files:"
    grep -n "$search_term" "$path_to_files"/*.md
}

mark_task_done() {
    line_number="$1"
    sed -i "${line_number}s/^- /- [x] /" "$file.md"
    echo "Task on line ${line_number} marked as done."
}

open_file_in_editor() {
    if [ -z "$EDITOR" ]; then
        echo "Error: $EDITOR environment variable is not set. Please set it to your preferred editor (e.g., export EDITOR=nano)."
        exit 1
    fi
    "$EDITOR" "$file.md"
    echo "Opened $file.md in $EDITOR."
}

load_config() {
    local config_file="${HOME}/.woche/config"

    # Set default
    export WOCHE_LANGUAGE="en"

    # Load config if exists
    if [ -f "$config_file" ]; then
        source "$config_file"
    fi

    # Apply language configuration
    if [ "$WOCHE_LANGUAGE" = "de" ]; then
        week_array=("${woche_array[@]}")
        week_array_string=("${woche_array_string[@]}")
        export week_array
        export week_array_string
    fi

    # Rebuild options_to_check with correct language
    export options_to_check=("${options[@]}" "${week_array_string[@]}")
}

show_config() {
    local config_file="${HOME}/.woche/config"

    echo "Current configuration:"
    echo ""
    echo "WOCHE_LANGUAGE: ${WOCHE_LANGUAGE:-en} (Language for day names: en=English, de=German)"
    echo ""
    echo "Config file: $config_file"

    if [ ! -f "$config_file" ]; then
        echo "Status: Using defaults (config file does not exist)"
    else
        echo "Status: Config file found"
    fi
}

set_language() {
    local new_language="$1"
    local config_dir="${HOME}/.woche"
    local config_file="$config_dir/config"

    # Validate language
    if [ "$new_language" != "en" ] && [ "$new_language" != "de" ]; then
        echo "Error: Invalid language '$new_language'. Use 'en' or 'de'."
        exit 1
    fi

    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"

    # Update or create config file
    if [ -f "$config_file" ]; then
        # Update existing config
        if grep -q "^WOCHE_LANGUAGE=" "$config_file"; then
            sed -i "s/^WOCHE_LANGUAGE=.*/WOCHE_LANGUAGE=\"$new_language\"/" "$config_file"
        else
            echo "WOCHE_LANGUAGE=\"$new_language\"" >> "$config_file"
        fi
    else
        # Create new config file
        cat > "$config_file" << EOF
# Woche Configuration File

# Language for day names: en (English) or de (German)
WOCHE_LANGUAGE="$new_language"
EOF
    fi

    echo "Language set to: $new_language"
    echo "Config saved to: $config_file"
    echo ""
    echo "Note: This language setting applies to NEW files created from now on."
    echo "Existing files will continue to be displayed correctly regardless of this setting."
}
