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
    all                         List all weekly files

    done <day> <n>              Mark the n-th task of a day as complete (e.g. done mon 2)
    edit <day> <n> "<new_task>" Edit the n-th task of a day (keeps it done if it was)
    delete <day> <n>            Delete the n-th task of a day (requires confirmation)
                                'show' prints each task's address (mon.2); 'mon.2' works
                                too, and so does a plain line number of the file

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
    woche.sh done mon 2
    woche.sh edit tue 1 "Call the bank"
    woche.sh search "meeting"
    woche.sh config
    woche.sh config language de
    woche.sh config dir ~/Documents/woche

ENVIRONMENT:
    WOCHE_DIR, WOCHE_LANGUAGE   Override the config file (~/.woche/config)
    WOCHE_WEEK=YYMMDD           Work on another week (its Monday), e.g. to create
                                or fill last week: WOCHE_WEEK=260921 woche.sh fri "..."

For more information, visit: https://github.com/0jonjo/woche
EOF
}

# YYMMDD -> YYYY-MM-DD, so date(1) never has to guess
week_to_date() {
    echo "20${1:0:2}-${1:2:2}-${1:4:2}"
}

current_week() {
    if [ -n "${WOCHE_WEEK:-}" ]; then
        if ! valid_week "$WOCHE_WEEK"; then
            echo "Error: WOCHE_WEEK must be the Monday of a week as YYMMDD (got '$WOCHE_WEEK')."
            exit 1
        fi
        current_week="$WOCHE_WEEK"
        return
    fi

    current_week=$(date -d "last monday" "+%y%m%d")

    if [ "$(date "+%u")" == 1 ]; then
        current_week=$(date "+%y%m%d")
    fi
}

valid_week() {
    [[ "$1" =~ ^[0-9]{6}$ ]] && [ "$(date -d "$(week_to_date "$1")" "+%u" 2> /dev/null)" = 1 ]
}

last_week() {
    last_week=$(date -d "$(week_to_date "$current_week") -7 days" "+%y%m%d")
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

create_file() {
    create_week
    echo "The file $file.md has been created."
}

create_week() {
    local week_date
    local i

    week_date=$(week_to_date "$current_week")
    for i in "${!week_array[@]}"; do
        printf "# %s, %s\n\n" "${week_array[$i]}" "$(date -d "$week_date +$i days" "+%-d/%-m")" >> "$file.md"
    done
}

# --- Week file format ---------------------------------------------------
# A week file is a list of days, each one a header followed by its tasks:
#
#   # Monday, 28/9
#   - open task
#   - [x] finished task
#
# Everything below reads and writes the file through these helpers.

# Usage: day_header_line <full day name>
day_header_line() {
    awk -v header="# $1," 'index($0, header) == 1 { print NR; exit }' "$file.md"
}

# Usage: day_task_lines <full day name>   (one line number per task, in order)
day_task_lines() {
    awk -v header="# $1," '
        /^# / { in_day = (index($0, header) == 1); next }
        in_day && /^- / { print NR }
    ' "$file.md"
}

is_task_line() {
    [[ "$1" =~ ^[1-9][0-9]*$ ]] && sed -n "${1}p" "$file.md" | grep -q '^- '
}

# Usage: day_insert_line <full day name>
# Where a new task goes: after the day's last task (and its indented lines), or the header
day_insert_line() {
    awk -v header="# $1," '
        /^# / { in_day = (index($0, header) == 1); if (in_day) last = NR; next }
        in_day && /^- / { last = NR; after_task = 1; next }
        in_day && after_task && /^[ \t]+[^ \t]/ { last = NR; next }
        { after_task = 0 }
        END { print last }
    ' "$file.md"
}

# Usage: write_line <insert-after|replace|delete> <line number> [text]
write_line() {
    local tmp
    local status

    tmp=$(mktemp) || exit 1
    OP="$1" N="$2" TEXT="${3:-}" awk '
        NR == ENVIRON["N"] {
            if (ENVIRON["OP"] == "insert-after") { print; print ENVIRON["TEXT"]; next }
            if (ENVIRON["OP"] == "replace") { print ENVIRON["TEXT"]; next }
            if (ENVIRON["OP"] == "delete") { next }
        }
        { print }
    ' "$file.md" > "$tmp" && cat "$tmp" > "$file.md"
    status=$?
    rm -f "$tmp"
    if [ "$status" -ne 0 ]; then
        echo "Error: Could not write $file.md."
        exit 1
    fi
}

# Index (0-6) of a day abbreviation, English or German
day_index() {
    local i
    for i in "${!english_day_abbrs[@]}"; do
        if [ "${english_day_abbrs[$i]}" = "$1" ] || [ "${german_day_abbrs[$i]}" = "$1" ]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

# Day names and abbreviations in the language the week file was written in
load_file_days() {
    if [ "$(detect_file_language "$file.md")" = "de" ]; then
        file_day_names=("${woche_array[@]}")
        file_day_abbrs=("${german_day_abbrs[@]}")
    else
        file_day_names=("${english_day_names[@]}")
        file_day_abbrs=("${english_day_abbrs[@]}")
    fi
}

# Resolves a task address into task_line and task_label; the arguments after
# the address are left in task_rest. Accepted: "<day> <n>", "<day>.<n>" and,
# for compatibility, a plain line number.
resolve_task() {
    local day
    local n
    local index

    if [[ "$1" =~ ^[0-9]+$ ]]; then
        task_label="Line $1"
        task_rest=("${@:2}")
        if ! task_line=$(task_number "$1") || ! is_task_line "$task_line"; then
            echo "Error: Line $1 is not a task."
            exit 1
        fi
        return
    fi

    if [[ "$1" =~ ^([a-z]+)\.([0-9]+)$ ]]; then
        day="${BASH_REMATCH[1]}"
        n="${BASH_REMATCH[2]}"
        task_rest=("${@:2}")
    elif [[ "${2:-}" =~ ^[0-9]+$ ]]; then
        day="$1"
        n="$2"
        task_rest=("${@:3}")
    else
        echo "Error: Tell which task, e.g. 'mon 2' (the second task on Monday)."
        exit 1
    fi

    if ! index=$(day_index "$day"); then
        echo "Error: Invalid day '$day'."
        exit 1
    fi

    load_file_days
    task_label="Task ${file_day_abbrs[$index]}.$n"
    if ! n=$(task_number "$n"); then
        echo "Error: $task_label does not exist."
        exit 1
    fi
    task_label="Task ${file_day_abbrs[$index]}.$n"
    task_line=$(day_task_lines "${file_day_names[$index]}" | sed -n "${n}p")
    if [ -z "$task_line" ]; then
        echo "Error: $task_label does not exist."
        exit 1
    fi
}

# A positive number without leading zeros (fails for 0 or absurdly big numbers)
task_number() {
    if [[ "$1" =~ ^0*([1-9][0-9]{0,6})$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        return 1
    fi
}

# Usage: no_extra_args <how many arguments may follow the task address>
no_extra_args() {
    if [ "${#task_rest[@]}" -gt "$1" ]; then
        too_many_args
    fi
}

# Usage: max_args <n> "$@"-style check against the command line ($# of woche.sh)
max_args() {
    if [ "$woche_argc" -gt "$1" ]; then
        too_many_args
    fi
}

too_many_args() {
    echo "Error: Too many arguments. Put text with spaces in quotes, e.g.: ${woche_name:-woche} mon \"Buy milk\""
    exit 1
}

task_at() {
    sed -n "${1}p" "$file.md"
}

delete_task() {
    local confirm

    read -r -p "Delete '$(task_at "$task_line")'? (y/N): " confirm
    if [[ "$confirm" =~ ^[yY]$ ]]; then
        write_line delete "$task_line"
        echo "$task_label deleted."
    else
        echo "Deletion cancelled."
    fi
}

edit_task() {
    local prefix="- "

    if [ -z "$task_text" ]; then
        echo "Error: Please give the new text for the task."
        exit 1
    fi

    # Keep a finished task finished
    if task_at "$task_line" | grep -q '^- \[[xX]\] ' && [[ "$task_text" != "[x] "* ]]; then
        prefix="- [x] "
    fi

    write_line replace "$task_line" "$prefix$task_text"
    echo "$task_label edited."
}

mark_task_done() {
    local line

    line=$(task_at "$task_line")
    if [[ "$line" == "- [x] "* ]] || [[ "$line" == "- [X] "* ]]; then
        echo "$task_label is already done."
        return
    fi

    line="${line#- }"
    write_line replace "$task_line" "- [x] ${line#"[ ] "}"
    echo "$task_label marked as done."
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
    local i
    local header
    local legend_string=""
    local day_tasks

    load_file_days

    printf "Week starts on %s.\n\n" "$(date -d "$(week_to_date "$file")" "+%d/%m/%Y")"

    for i in "${!file_day_names[@]}"; do
        header=$(grep -m1 "^# ${file_day_names[$i]}," "$file.md")
        header="${header%$'\r'}"
        if [ -n "$header" ]; then
            if [ -n "$legend_string" ]; then
                legend_string+=", "
            fi
            legend_string+="${file_day_abbrs[$i]} (${header#*, })"
        fi
    done
    printf "Current week: %s\n\n" "$legend_string"

    for i in "${!file_day_names[@]}"; do
        day_tasks=$(awk -v header="# ${file_day_names[$i]}," -v abbr="${file_day_abbrs[$i]}" '
            /^# / { in_day = (index($0, header) == 1); next }
            { sub(/\r$/, "") }
            in_day && /^- / { print $0 " (" abbr "." ++n ")" }
        ' "$file.md")

        if [ -n "$day_tasks" ]; then
            printf "%s:\n%s\n\n" "${file_day_names[$i]}" "$day_tasks"
        fi
    done
}

weekly_files_glob="[0-9][0-9][0-9][0-9][0-9][0-9].md"

show_all_files() {
    echo "All markdown files in $WOCHE_DIR:"
    # shellcheck disable=SC2086  # the glob must expand
    ls -1 $weekly_files_glob 2> /dev/null
}

add_task() {
    local day_name="$1"
    local task_text="$2"
    local header_line

    header_line=$(day_header_line "$day_name")

    # Check if the day header exists in the file
    if [ -z "$header_line" ]; then
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

    if [ -z "$task_text" ]; then
        echo "Error: Please give the task text."
        exit 1
    fi

    # New tasks go to the end of the day
    write_line insert-after "$(day_insert_line "$day_name")" "- $task_text"
    echo "Task '$task_text' added to $day_name."
}

search_files() {
    local search_term="$1"

    echo "Searching for '$search_term' in markdown files:"
    # shellcheck disable=SC2086  # the glob must expand
    grep -HnF -- "$search_term" $weekly_files_glob 2> /dev/null
}

open_file_in_editor() {
    if [ -z "$EDITOR" ]; then
        echo "Error: The EDITOR environment variable is not set. Please set it to your preferred editor (e.g., export EDITOR=nano)."
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

    # What the config file alone says ('woche init' suggests these).
    # A relative directory in the config is relative to HOME, not to where woche runs.
    woche_config_language="$WOCHE_LANGUAGE"
    woche_config_dir="$WOCHE_DIR"
    if [ -n "$woche_config_dir" ]; then
        woche_config_dir=$(cd "$HOME" && normalize_dir "$woche_config_dir")
    fi

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
    if [ -n "$woche_env_language" ] && [ -n "$woche_env_dir" ]; then
        return
    fi
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

# Absolute path, with a leading ~ or ~user expanded (also when it came quoted)
normalize_dir() {
    local dir="$1"
    local user
    local user_home

    # shellcheck disable=SC2088  # matching a literal ~ on purpose
    case "$dir" in
        "~") dir="$HOME" ;;
        "~/"*) dir="$HOME/${dir#"~/"}" ;;
        "~"*)
            user="${dir%%/*}"
            user="${user#"~"}"
            user_home=$(getent passwd -- "$user" | cut -d: -f6)
            if [ -n "$user_home" ]; then
                dir="$user_home${dir#"~$user"}"
            fi
            ;;
    esac
    realpath -ms -- "$dir"
}

# A v1.5 config has no WOCHE_DIR: say where the files are read from now.
# Only on a terminal, so cron mails and scripts stay quiet.
missing_dir_hint() {
    if [ -f "$WOCHE_CONFIG" ] && [ -z "$woche_config_dir" ] && [ -z "$woche_env_dir" ] && [ -t 2 ]; then
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
        # A new config gets both settings (config/default values, never the
        # environment), so it is complete whatever the first command was
        {
            echo "# Woche Configuration File"
            printf 'WOCHE_LANGUAGE=%q\n' "${woche_config_language:-en}"
            printf 'WOCHE_DIR=%q\n' "${woche_config_dir:-$(normalize_dir "${HOME}/woche")}"
        } > "$WOCHE_CONFIG" || return 1
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
