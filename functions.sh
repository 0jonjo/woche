#!/usr/bin/env bash
# shellcheck disable=SC2154  # globals (file, task, new_task, day names) come from woche.sh and variables.sh

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

    init                        Set up language and directory (asked on first run)
    config                      Show current configuration
    config language <en|de>     Set language for day names (applies to new files only)
    config dir <path>           Set the directory for weekly files (files are not moved)

    help                        Show this help message
    --version                   Show the version

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
    read -r -p "Are you sure you want to delete line ${task}? (y/N): " confirm
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
    echo "All markdown files in $WOCHE_DIR:"
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
    grep -n "$search_term" ./*.md
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
    # Environment variables take precedence over the config file
    woche_env_language="${WOCHE_LANGUAGE:-}"
    woche_env_dir="${WOCHE_DIR:-}"

    WOCHE_LANGUAGE=""
    WOCHE_DIR=""
    if [ -f "$WOCHE_CONFIG" ]; then
        # shellcheck source=/dev/null
        source "$WOCHE_CONFIG"
    fi

    # What the config file alone says ('woche init' suggests these)
    woche_config_language="$WOCHE_LANGUAGE"
    woche_config_dir="$WOCHE_DIR"

    WOCHE_LANGUAGE="${woche_env_language:-${woche_config_language:-en}}"
    WOCHE_DIR="${woche_env_dir:-${woche_config_dir:-${HOME}/woche}}"

    if ! valid_language "$WOCHE_LANGUAGE"; then
        echo "Warning: Invalid language '$WOCHE_LANGUAGE', using 'en'." >&2
        WOCHE_LANGUAGE="en"
    fi
    WOCHE_DIR=$(normalize_dir "$WOCHE_DIR")
    export WOCHE_LANGUAGE WOCHE_DIR

    apply_language
}

valid_language() {
    [ "$1" = "en" ] || [ "$1" = "de" ]
}

apply_language() {
    if [ "$WOCHE_LANGUAGE" = "de" ]; then
        week_array=("${woche_array[@]}")
        week_array_string=("${woche_array_string[@]}")
    else
        week_array=("$mon" "$tue" "$wed" "$thu" "$fri" "$sat" "$sun")
        week_array_string=("mon" "tue" "wed" "thu" "fri" "sat" "sun")
    fi

    # Rebuild options_to_check with correct language
    options_to_check=("${options[@]}" "${week_array_string[@]}")
}

valid_command() {
    local option
    for option in "${options_to_check[@]}"; do
        if [ "$option" = "$1" ]; then
            return 0
        fi
    done
    return 1
}

# Without a config file, an interactive run asks for the settings first.
# Scripts, cron and tests (no TTY) silently use the defaults instead.
first_run_setup() {
    if [ ! -f "$WOCHE_CONFIG" ] && [ -t 0 ] && [ -t 1 ]; then
        echo "Welcome to woche! Let's set it up (run 'woche.sh init' to change it later)."
        echo ""
        woche_init
        echo ""
    fi
}

language_from_locale() {
    case "${LC_ALL:-${LANG:-}}" in
        de*) echo "de" ;;
        *) echo "en" ;;
    esac
}

# Absolute path, with a leading ~ expanded (also when it came quoted from the config)
normalize_dir() {
    local dir="$1"
    # shellcheck disable=SC2088  # matching a literal ~ on purpose
    case "$dir" in
        "~") dir="$HOME" ;;
        "~/"*) dir="$HOME/${dir#"~/"}" ;;
    esac
    realpath -ms -- "$dir"
}

# A v1.5 config has no WOCHE_DIR: say where the files are read from now
missing_dir_hint() {
    if [ -f "$WOCHE_CONFIG" ] && [ -z "$woche_config_dir" ] && [ -z "$woche_env_dir" ]; then
        echo "Note: WOCHE_DIR is not set in $WOCHE_CONFIG, using $WOCHE_DIR." >&2
        echo "      Run 'woche.sh config dir <path>' to choose the directory of your weekly files." >&2
    fi
}

woche_init() {
    local default_language default_dir language dir

    if valid_language "$woche_config_language"; then
        default_language="$woche_config_language"
    else
        default_language=$(language_from_locale)
    fi
    default_dir=$(normalize_dir "${woche_config_dir:-${HOME}/woche}")

    # EOF (Ctrl-D) cancels without writing anything
    while true; do
        read -r -p "Language for day names [en/de] (default: $default_language): " language || init_cancelled
        language="${language:-$default_language}"
        if valid_language "$language"; then
            break
        fi
        echo "Please answer 'en' or 'de'."
    done

    read -r -p "Directory for weekly files (default: $default_dir): " dir || init_cancelled
    dir=$(normalize_dir "${dir:-$default_dir}")

    if ! mkdir -p -- "$dir"; then
        echo "Error: Could not create directory '$dir'."
        exit 1
    fi

    set_config_value WOCHE_LANGUAGE "$language" || config_write_failed
    set_config_value WOCHE_DIR "$dir" || config_write_failed

    echo "Configuration saved to $WOCHE_CONFIG"
    echo "  Language:  $language"
    echo "  Directory: $dir"
    warn_env_override WOCHE_LANGUAGE "$woche_env_language"
    warn_env_override WOCHE_DIR "$woche_env_dir"

    # Keep running with the new values, unless the environment overrides them
    woche_config_language="$language"
    woche_config_dir="$dir"
    if [ -z "$woche_env_language" ]; then
        WOCHE_LANGUAGE="$language"
    fi
    if [ -z "$woche_env_dir" ]; then
        WOCHE_DIR="$dir"
    fi
    apply_language
}

init_cancelled() {
    echo ""
    echo "Setup cancelled, nothing was saved."
    exit 1
}

config_write_failed() {
    echo "Error: Could not write $WOCHE_CONFIG."
    exit 1
}

# Usage: warn_env_override <variable name> <value from the environment>
warn_env_override() {
    if [ -n "$2" ]; then
        echo ""
        echo "Warning: $1 is set in your environment and overrides the config file."
    fi
}

# Set KEY=value in the config file, replacing the existing line if there is one.
# Writes through the file (not mv) so a symlinked config keeps working.
set_config_value() {
    local key="$1"
    local value="$2"
    local tmp
    local status

    mkdir -p "$(dirname "$WOCHE_CONFIG")" || return 1
    if [ ! -f "$WOCHE_CONFIG" ]; then
        echo "# Woche Configuration File" > "$WOCHE_CONFIG" || return 1
    fi

    tmp=$(mktemp) || return 1
    KEY="$key" LINE="$(printf '%s=%q' "$key" "$value")" awk '
        index($0, ENVIRON["KEY"] "=") == 1 {
            if (!replaced) print ENVIRON["LINE"]
            replaced = 1
            next
        }
        { print }
        END { if (!replaced) print ENVIRON["LINE"] }
    ' "$WOCHE_CONFIG" > "$tmp" && cat "$tmp" > "$WOCHE_CONFIG"
    status=$?
    rm -f "$tmp"
    return $status
}

show_config() {
    local language_source="default"
    local dir_source="default"

    if [ -n "$woche_env_language" ]; then
        language_source="environment"
    elif [ -n "$woche_config_language" ]; then
        language_source="config file"
    fi
    if [ -n "$woche_env_dir" ]; then
        dir_source="environment"
    elif [ -n "$woche_config_dir" ]; then
        dir_source="config file"
    fi

    echo "Current configuration:"
    echo ""
    echo "WOCHE_LANGUAGE: $WOCHE_LANGUAGE (Language for day names: en=English, de=German) [$language_source]"
    echo "WOCHE_DIR:      $WOCHE_DIR (Where the weekly files are stored) [$dir_source]"
    echo ""
    echo "Config file: $WOCHE_CONFIG"

    if [ ! -f "$WOCHE_CONFIG" ]; then
        echo "Status: Using defaults (config file does not exist). Run 'woche.sh init' to set it up."
    else
        echo "Status: Config file found"
    fi
}

set_language() {
    local new_language="$1"

    # Validate language
    if ! valid_language "$new_language"; then
        echo "Error: Invalid language '$new_language'. Use 'en' or 'de'."
        exit 1
    fi

    set_config_value WOCHE_LANGUAGE "$new_language" || config_write_failed

    echo "Language set to: $new_language"
    echo "Config saved to: $WOCHE_CONFIG"
    echo ""
    echo "Note: This language setting applies to NEW files created from now on."
    echo "Existing files will continue to be displayed correctly regardless of this setting."
    warn_env_override WOCHE_LANGUAGE "$woche_env_language"
}

set_dir() {
    local new_dir
    local old_dir

    new_dir=$(normalize_dir "$1")
    old_dir="$WOCHE_DIR"

    if ! mkdir -p -- "$new_dir"; then
        echo "Error: Could not create directory '$new_dir'."
        exit 1
    fi

    set_config_value WOCHE_DIR "$new_dir" || config_write_failed

    echo "Directory set to: $new_dir"
    echo "Config saved to: $WOCHE_CONFIG"

    # Files are never moved automatically
    if [ "$old_dir" != "$new_dir" ] && compgen -G "$old_dir/[0-9][0-9][0-9][0-9][0-9][0-9].md" > /dev/null; then
        echo ""
        echo "Note: The weekly files in $old_dir were not moved. To move them, run:"
        printf '    mv -n %q/[0-9][0-9][0-9][0-9][0-9][0-9].md %q/\n' "$old_dir" "$new_dir"
    fi

    warn_env_override WOCHE_DIR "$woche_env_dir"
}
