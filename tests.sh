#!/usr/bin/env bash

# Run everything in a throwaway HOME and WOCHE_DIR: never touches the
# user's config, weekly files or the source tree.
test_root=$(mktemp -d) || exit 1
trap 'rm -rf "$test_root"' EXIT

export HOME="$test_root/home"
export WOCHE_DIR="$test_root/files"
unset WOCHE_LANGUAGE LC_ALL
mkdir -p "$HOME"

repo_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
woche_script_path="$repo_dir/woche.sh"
q_woche_script_path=$(printf %q "$woche_script_path")

# shellcheck source=functions.sh
source "$repo_dir/functions.sh"
# shellcheck source=variables.sh
source "$repo_dir/variables.sh"

current_week
file=$current_week

# Usage: assert_contains "<test name>" "<output>" "<expected substring>"
assert_contains() {
    if [[ "$2" == *"$3"* ]]; then
        echo "Test $1: PASSED"
    else
        echo "Test $1: FAILED"
        echo "  expected to contain: $3"
        echo "  got: $2"
        exit 1
    fi
}

# Test with more than 4 arguments
output=$("$woche_script_path" edit mon 1 "Test task" "Extra argument")
if [[ "$output" == *"Error: Too many arguments."* ]]; then
    echo "Test 'more than 4 arguments' command: PASSED"
else
    echo "Test 'more than 4 arguments' command: FAILED"
    exit 1
fi

#  Test if the file do not exists - show command
output=$("$woche_script_path" show)
if [[ "$output" == *"Error: The file"* ]]; then
    echo "Test if the file do not exists - show command: PASSED"
else
    echo "Test if the file do not exists - show command: FAILED"
    exit 1
fi

# Test if the file do not exists - delete command
output=$("$woche_script_path" delete 2)
if [[ "$output" == *"Error: The file"* ]]; then
    echo "Test if the file do not exists - delete command: PASSED"
else
    echo "Test if the file do not exists- delete command: FAILED"
    exit 1
fi

# Test if the file do not exists - edit command
output=$("$woche_script_path" edit 2 "New task")
if [[ "$output" == *"Error: The file"* ]]; then
    echo "Test if the file do not exists - edit command: PASSED"
else
    echo "Test if the file do not exists - edit command: FAILED"
    exit 1
fi

# Test invalid command
output=$("$woche_script_path" invalid)
if [[ "$output" == *"Woche - Weekly Task Manager"* ]]; then
    echo "Test invalid command: PASSED"
else
    echo "Test invalid command: FAILED"
    exit 1
fi

# Test the 'help' command
output=$("$woche_script_path" help)
if [[ "$output" == *"Woche - Weekly Task Manager"* ]]; then
    echo "Test 'help' command: PASSED"
else
    echo "Test 'help' command: FAILED"
    exit 1
fi

# Test the 'create' command
output=$("$woche_script_path" create)
if [[ "$output" == *"The file"*"has been created."* ]]; then
    echo "Test 'create' command: PASSED"
else
    echo "Test 'create' command: FAILED"
    exit 1
fi

# Test the 'create' command when the file already exists
output=$("$woche_script_path" create)
if [[ "$output" == *"The file"*"already exists."* ]]; then
    echo "Test 'create' command when the file already exists: PASSED"
else
    echo "Test 'create' command when the file already exists: FAILED"
    exit 1
fi

## Check if the file is created on last test
cd "$WOCHE_DIR" > /dev/null || exit
if [ ! -e "$file.md" ]; then
    echo "Error: The file $file.md does not exist."
    exit 1
fi
cd - > /dev/null || exit

# Check if the # Monday was added to the file
cd "$WOCHE_DIR" > /dev/null || exit
if [ -z "$(sed -n "/# $mon/ p" "$file.md")" ]; then
    echo "Error: The day of the week is not written in the file."
    exit 1
fi
cd - > /dev/null || exit

# Test the last command
cd "$WOCHE_DIR" > /dev/null || exit
last_week=$(date -d "$current_week - 7 days" "+%y%m%d")
cp "$file.md" "$last_week.md"
cd - > /dev/null || exit

output=$("$woche_script_path" show last)
if [[ "$output" == *"Week starts on"* ]]; then
    echo "Test 'last week' command: PASSED"
else
    echo "Test 'last week' command: FAILED"
    exit 1
fi

# Test the all command
output=$("$woche_script_path" all)
if [[ "$output" == "All markdown files in $WOCHE_DIR:"* ]]; then
    echo "Test 'all' command: PASSED"
else
    echo "Test 'all' command: FAILED"
    exit 1
fi

# Test add task to a day command
output=$("$woche_script_path" mon "Test task")
if [[ "$output" == *"Task 'Test task' added to"* ]]; then
    echo "Test 'add task to a day' command: PASSED"
else
    echo "Test 'add task to a day' command: FAILED"
    exit 1
fi

## Check if the task is added on last test
cd "$WOCHE_DIR" > /dev/null || exit
if ! grep -q "^- Test task$" "$file.md"; then
    echo "Error: Task has not been added."
    exit 1
fi
cd - > /dev/null || exit

# Test add task with punctituation to a day command
output=$("$woche_script_path" mon "Test task with punctuation: ;,!@#$%^&*()_+")
if [[ "$output" == *"Task 'Test task with punctuation: ;,!@#$%^&*()_+' added to"* ]]; then
    echo "Test 'add task to a day' command: PASSED"
else
    echo "Test 'add task to a day' command: FAILED"
    exit 1
fi

# Test edit command with punctituation
line_to_edit=$(grep -n "Test task with punctuation" "$WOCHE_DIR/$file.md" | cut -d: -f1)
output=$("$woche_script_path" edit "$line_to_edit" "New task ,.!@")
if [[ "$output" == *"Line $line_to_edit edited."* ]]; then
    echo "Test 'edit' command: PASSED"
else
    echo "Test 'edit' command: FAILED"
    exit 1
fi

## Check if the task is edited on last test
cd "$WOCHE_DIR" > /dev/null || exit
if ! sed -n "${line_to_edit}p" "$file.md" | grep -q "New task ,.!@"; then
    echo "Error: Task has not been edited."
    exit 1
fi
cd - > /dev/null || exit

# Test show command
output=$("$woche_script_path" create)
output=$("$woche_script_path" mon "Task one")
output=$("$woche_script_path" mon "Task two")
output=$("$woche_script_path" tue "Task three")


output=$("$woche_script_path" show)

if [[ "$output" == *"Week starts on"* ]] && \
   [[ "$output" == *"Task one"* ]] && \
   [[ "$output" == *"Task two"* ]] && \
   [[ "$output" == *"Task three"* ]]; then
    echo "Test 'show' command: PASSED"
else
    echo "Test 'show' command: FAILED"
    exit 1
fi

# Test 'today' command
output=$("$woche_script_path" today "Test task")
if [[ "$output" == *"Task 'Test task' added to"* ]]; then
    echo "Test 'today' command: PASSED"
else
    echo "Test 'today' command: FAILED"
    exit 1
fi

# Test 'search' command
output=$("$woche_script_path" create)
output=$("$woche_script_path" mon "Searchable task")
output=$("$woche_script_path" search "Searchable task")
if [[ "$output" == *"Searchable task"* ]]; then
    echo "Test 'search' command: PASSED"
else
    echo "Test 'search' command: FAILED"
    exit 1
fi

# Test delete command with 'y' confirmation
output=$("$woche_script_path" create)
output=$("$woche_script_path" mon "Task to be deleted")
line_to_delete=$(grep -n "Task to be deleted" "$WOCHE_DIR/$file.md" | cut -d: -f1)
output=$(echo "y" | "$woche_script_path" delete "$line_to_delete")
if [[ "$output" == *"Line $line_to_delete deleted."* ]]; then
    echo "Test 'delete' command with 'y' confirmation: PASSED"
else
    echo "Test 'delete' command with 'y' confirmation: FAILED"
    exit 1
fi

## Check if the task is deleted on last test
cd "$WOCHE_DIR" > /dev/null || exit
if grep -q "Task to be deleted" "$file.md"; then
    echo "Error: Task has not been deleted."
    exit 1
fi
cd - > /dev/null || exit

# Test delete command with 'n' confirmation
output=$("$woche_script_path" create)
output=$("$woche_script_path" mon "Task not to be deleted")
line_to_delete=$(grep -n "Task not to be deleted" "$WOCHE_DIR/$file.md" | cut -d: -f1)
output=$(echo "n" | "$woche_script_path" delete "$line_to_delete")
if [[ "$output" == *"Deletion cancelled."* ]]; then
    echo "Test 'delete' command with 'n' confirmation: PASSED"
else
    echo "Test 'delete' command with 'n' confirmation: FAILED"
    exit 1
fi

## Check if the task is not deleted on last test
cd "$WOCHE_DIR" > /dev/null || exit
if ! grep -q "Task not to be deleted" "$file.md"; then
    echo "Error: Task has been deleted when it shouldn't have been."
    exit 1
fi
cd - > /dev/null || exit

# Test 'done' command
output=$("$woche_script_path" create)
output=$("$woche_script_path" mon "Task to be marked as done")
line_to_mark_done=$(grep -n "Task to be marked as done" "$WOCHE_DIR/$file.md" | cut -d: -f1)
output=$("$woche_script_path" "done" "$line_to_mark_done")
if [[ "$output" == *"Line $line_to_mark_done marked as done."* ]]; then
    echo "Test 'done' command: PASSED"
else
    echo "Test 'done' command: FAILED"
    exit 1
fi

## Check if the task is marked as done on last test
cd "$WOCHE_DIR" > /dev/null || exit
if ! sed -n "${line_to_mark_done}p" "$file.md" | grep -q '^- \[x\] Task to be marked as done'; then
    echo "Error: Task has not been marked as done."
    exit 1
fi
cd - > /dev/null || exit

# Test config language command
output=$("$woche_script_path" config language en)
if [[ "$output" == *"Language set to: en"* ]]; then
    echo "Test 'config language' command: PASSED"
else
    echo "Test 'config language' command: FAILED"
    exit 1
fi

# Check if config file was created
if [ -f "$HOME/.woche/config" ]; then
    echo "Test config file creation: PASSED"
else
    echo "Test config file creation: FAILED"
    exit 1
fi

# Test automatic language detection
# Create file in English
output=$("$woche_script_path" create)
output=$("$woche_script_path" mon "English task")

# Switch to German and verify show still works
output=$("$woche_script_path" config language de)
output=$("$woche_script_path" show)
if [[ "$output" == *"English task"* ]]; then
    echo "Test automatic language detection: PASSED"
else
    echo "Test automatic language detection: FAILED"
    exit 1
fi

# Test error when using wrong language commands
output=$("$woche_script_path" mont "German task" 2>&1)
if [[ "$output" == *"Error: This file uses English day names"* ]]; then
    echo "Test language mismatch detection: PASSED"
else
    echo "Test language mismatch detection: FAILED"
    exit 1
fi

# Commands that run with a different HOME / WOCHE_DIR use this helper
# Usage: woche_in <home> [VAR=value...] -- <args...>  (WOCHE_DIR is unset unless given)
woche_in() {
    local home="$1"
    shift
    local -a vars=()
    while [ "$1" != "--" ]; do
        vars+=("$1")
        shift
    done
    shift
    mkdir -p "$home"
    env -u WOCHE_DIR -u WOCHE_LANGUAGE HOME="$home" "${vars[@]}" "$woche_script_path" "$@"
}

# Test '--version' command
output=$("$woche_script_path" --version)
assert_contains "'--version' command" "$output" "woche $WOCHE_VERSION"

# Test no arguments shows help
output=$("$woche_script_path")
assert_contains "no arguments shows help" "$output" "Woche - Weekly Task Manager"

# Test partial command names are rejected (the check used to match substrings)
output=$("$woche_script_path" sho)
assert_contains "partial command is rejected" "$output" "Error: Invalid command."

# Test running through a symlink from another directory
mkdir -p "$test_root/bin"
ln -s "$woche_script_path" "$test_root/bin/woche"
output=$(cd / && "$test_root/bin/woche" show)
assert_contains "runs through a symlink from another directory" "$output" "Week starts on"

# Test first run without a TTY uses the defaults and does not write a config
home="$test_root/first_run"
output=$(cd / && woche_in "$home" -- create)
assert_contains "first run without TTY creates the file" "$output" "has been created."
if [ -e "$home/woche/$current_week.md" ] && [ ! -e "$home/.woche/config" ]; then
    echo "Test first run without TTY uses ~/woche and writes no config: PASSED"
else
    echo "Test first run without TTY uses ~/woche and writes no config: FAILED"
    exit 1
fi

# Test 'init' saves the answers
home="$test_root/init"
output=$(printf 'de\n%s\n' "$test_root/init_files" | woche_in "$home" -- init)
assert_contains "'init' saves the answers" "$output" "Configuration saved to $home/.woche/config"
config_content=$(cat "$home/.woche/config")
assert_contains "'init' writes the language" "$config_content" "WOCHE_LANGUAGE=de"
assert_contains "'init' writes the directory" "$config_content" "WOCHE_DIR=$test_root/init_files"
if [ -d "$test_root/init_files" ]; then
    echo "Test 'init' creates the directory: PASSED"
else
    echo "Test 'init' creates the directory: FAILED"
    exit 1
fi

# Test 'init' again suggests the current values
output=$(printf '\n\n' | woche_in "$home" -- init)
config_content=$(cat "$home/.woche/config")
assert_contains "'init' again keeps the language" "$config_content" "WOCHE_LANGUAGE=de"
assert_contains "'init' again keeps the directory" "$config_content" "WOCHE_DIR=$test_root/init_files"

# Test 'init' rejects an invalid language and asks again
output=$(printf 'fr\nen\n\n' | woche_in "$test_root/init_invalid" -- init)
assert_contains "'init' rejects an invalid language" "$output" "Please answer 'en' or 'de'."
assert_contains "'init' accepts the second answer" "$output" "Language:  en"

# Test 'init' defaults come from the locale and ~/woche
home="$test_root/init_locale"
output=$(printf '\n\n' | woche_in "$home" LANG=de_DE.UTF-8 -- init)
config_content=$(cat "$home/.woche/config")
assert_contains "'init' suggests the language from \$LANG" "$config_content" "WOCHE_LANGUAGE=de"
assert_contains "'init' suggests ~/woche" "$config_content" "WOCHE_DIR=$home/woche"

# Test environment overrides the config file
home="$test_root/init"
output=$(woche_in "$home" WOCHE_DIR="$test_root/env_files" WOCHE_LANGUAGE=en -- create)
if [ -e "$test_root/env_files/$current_week.md" ] && [ ! -e "$test_root/init_files/$current_week.md" ]; then
    echo "Test WOCHE_DIR overrides the config file: PASSED"
else
    echo "Test WOCHE_DIR overrides the config file: FAILED"
    exit 1
fi
output=$(woche_in "$home" WOCHE_DIR="$test_root/env_files" WOCHE_LANGUAGE=en -- config)
assert_contains "'config' shows the environment language" "$output" "WOCHE_LANGUAGE: en"
assert_contains "'config' shows where the dir comes from" "$output" "[environment]"

# Test 'config dir' keeps a v1.5 config and does not move files
home="$test_root/config_dir"
mkdir -p "$home/.woche"
printf '# Woche Configuration File\nWOCHE_LANGUAGE="de"\n' > "$home/.woche/config"
output=$(woche_in "$home" -- config dir "$test_root/old_dir")
output=$(woche_in "$home" -- create)
output=$(woche_in "$home" -- config dir "$test_root/new dir")
assert_contains "'config dir' sets the directory" "$output" "Directory set to: $test_root/new dir"
assert_contains "'config dir' warns about files left behind" "$output" "were not moved"
config_content=$(cat "$home/.woche/config")
assert_contains "'config dir' keeps the language" "$config_content" 'WOCHE_LANGUAGE="de"'
if [ "$(grep -c '^WOCHE_DIR=' "$home/.woche/config")" = 1 ] && \
   [ -e "$test_root/old_dir/$current_week.md" ] && [ -d "$test_root/new dir" ]; then
    echo "Test 'config dir' replaces the line and leaves the files: PASSED"
else
    echo "Test 'config dir' replaces the line and leaves the files: FAILED"
    exit 1
fi

# Test a directory with spaces works after 'config dir'
output=$(woche_in "$home" -- create)
assert_contains "directory with spaces" "$output" "has been created."
if [ -e "$test_root/new dir/$current_week.md" ]; then
    echo "Test file created in the directory with spaces: PASSED"
else
    echo "Test file created in the directory with spaces: FAILED"
    exit 1
fi

# Test 'config dir' expands ~
# shellcheck disable=SC2088
output=$(woche_in "$home" -- config dir "~/notes")
assert_contains "'config dir' expands ~" "$output" "Directory set to: $home/notes"

# Test 'init' cancels on EOF without writing a config
home="$test_root/init_eof"
output=$(woche_in "$home" -- init < /dev/null)
assert_contains "'init' cancels on EOF" "$output" "Setup cancelled, nothing was saved."
if [ ! -e "$home/.woche/config" ]; then
    echo "Test 'init' on EOF writes no config: PASSED"
else
    echo "Test 'init' on EOF writes no config: FAILED"
    exit 1
fi

# Test an invalid language in the config falls back to 'en' and is not suggested by 'init'
home="$test_root/bad_language"
mkdir -p "$home/.woche"
printf 'WOCHE_LANGUAGE="EN"\n' > "$home/.woche/config"
output=$(woche_in "$home" -- config 2>&1)
assert_contains "invalid language warns" "$output" "Warning: Invalid language 'EN', using 'en'."
output=$(printf '\n\n' | woche_in "$home" LANG=de_DE.UTF-8 -- init 2>/dev/null)
assert_contains "'init' ignores an invalid configured language" "$output" "Language:  de"

# Test a relative WOCHE_DIR works with search (woche cd's into it)
mkdir -p "$test_root/cwd"
output=$(cd "$test_root/cwd" && woche_in "$test_root/relative" WOCHE_DIR=notes -- create)
output=$(cd "$test_root/cwd" && woche_in "$test_root/relative" WOCHE_DIR=notes -- mon "findme")
output=$(cd "$test_root/cwd" && woche_in "$test_root/relative" WOCHE_DIR=notes -- search "findme" 2>&1)
assert_contains "relative WOCHE_DIR with search" "$output" "- findme"

# Test a quoted ~ in the config is expanded
home="$test_root/quoted_tilde"
mkdir -p "$home/.woche"
printf 'WOCHE_DIR="~/weeks"\n' > "$home/.woche/config"
output=$(cd "$test_root/cwd" && woche_in "$home" -- create)
if [ -e "$home/weeks/$current_week.md" ] && [ ! -e "$test_root/cwd/~" ]; then
    echo "Test quoted ~ in the config is expanded: PASSED"
else
    echo "Test quoted ~ in the config is expanded: FAILED"
    exit 1
fi

# Test a v1.5 config without WOCHE_DIR prints a hint
home="$test_root/v15"
mkdir -p "$home/.woche"
printf 'WOCHE_LANGUAGE="en"\n' > "$home/.woche/config"
output=$(woche_in "$home" -- show 2>&1)
if [[ "$output" == *"WOCHE_DIR is not set"* ]]; then
    echo "Test hint stays out of scripts (stderr not a TTY): FAILED"
    exit 1
else
    echo "Test hint stays out of scripts (stderr not a TTY): PASSED"
fi
output=$(env -u WOCHE_DIR HOME="$home" script -qec "$q_woche_script_path show" /dev/null)
assert_contains "v1.5 config without WOCHE_DIR prints a hint" "$output" "WOCHE_DIR is not set in"
env -u WOCHE_DIR HOME="$home" script -qec "$q_woche_script_path show > '$test_root/stdout.txt'" /dev/null > /dev/null
output=$(cat "$test_root/stdout.txt")
if [[ "$output" == *"WOCHE_DIR is not set"* ]] || [[ "$output" == *"to choose the directory"* ]]; then
    echo "Test hint goes to stderr: FAILED"
    exit 1
else
    echo "Test hint goes to stderr: PASSED"
fi
home="$test_root/init"
output=$(env -u WOCHE_DIR HOME="$home" script -qec "$q_woche_script_path show" /dev/null)
if [[ "$output" == *"WOCHE_DIR is not set"* ]]; then
    echo "Test no hint when the config has WOCHE_DIR: FAILED"
    exit 1
else
    echo "Test no hint when the config has WOCHE_DIR: PASSED"
fi

# Test a symlinked config keeps being a symlink
home="$test_root/symlinked"
mkdir -p "$home/.woche" "$test_root/dotfiles"
printf 'WOCHE_LANGUAGE="en"\n' > "$test_root/dotfiles/woche.conf"
ln -s "$test_root/dotfiles/woche.conf" "$home/.woche/config"
output=$(woche_in "$home" -- config language de)
if [ -L "$home/.woche/config" ] && grep -q '^WOCHE_LANGUAGE=de' "$test_root/dotfiles/woche.conf"; then
    echo "Test symlinked config keeps being a symlink: PASSED"
else
    echo "Test symlinked config keeps being a symlink: FAILED"
    exit 1
fi

# Test German mode rejects English day commands
output=$(woche_in "$home" -- mon "Task")
assert_contains "German mode rejects 'mon'" "$output" "Error: Invalid command."

# Test the first interactive run asks the questions before the command (needs a TTY: script)
home="$test_root/wizard"
mkdir -p "$home"
output=$(printf 'de\n%s\n' "$test_root/wizard_files" | \
    env -u WOCHE_DIR -u WOCHE_LANGUAGE HOME="$home" script -qec "$q_woche_script_path create" /dev/null)
assert_contains "first interactive run asks first" "$output" "Welcome to woche!"
assert_contains "first interactive run then runs the command" "$output" "has been created."
if grep -q "^# Montag," "$test_root/wizard_files/$current_week.md" 2> /dev/null; then
    echo "Test first interactive run uses the answers right away: PASSED"
else
    echo "Test first interactive run uses the answers right away: FAILED"
    exit 1
fi

# Test no wizard when stdin is not a terminal, even if stdout is
home="$test_root/wizard_no_stdin"
mkdir -p "$home"
output=$(env -u WOCHE_DIR -u WOCHE_LANGUAGE HOME="$home" script -qec "$q_woche_script_path create < /dev/null" /dev/null)
if [[ "$output" != *"Welcome to woche!"* ]] && [ ! -e "$home/.woche/config" ]; then
    echo "Test no wizard without a terminal on stdin: PASSED"
else
    echo "Test no wizard without a terminal on stdin: FAILED"
    exit 1
fi

# Test no wizard when the environment already sets everything
home="$test_root/wizard_env"
mkdir -p "$home"
output=$(env HOME="$home" WOCHE_DIR="$test_root/wizard_env_files" WOCHE_LANGUAGE=en \
    script -qec "$q_woche_script_path create < /dev/null" /dev/null)
output=$(env HOME="$home" WOCHE_DIR="$test_root/wizard_env_files" WOCHE_LANGUAGE=en \
    script -qec "$q_woche_script_path show" /dev/null)
if [[ "$output" != *"Welcome to woche!"* ]] && [ ! -e "$home/.woche/config" ]; then
    echo "Test no wizard when the environment sets everything: PASSED"
else
    echo "Test no wizard when the environment sets everything: FAILED"
    exit 1
fi

# Test 'config language' as the first command writes a complete config (no hint later)
home="$test_root/language_first"
output=$(woche_in "$home" -- config language de)
config_content=$(cat "$home/.woche/config")
assert_contains "'config language' first also writes WOCHE_DIR" "$config_content" "WOCHE_DIR=$home/woche"

# Test a relative WOCHE_DIR in the config is relative to HOME, not to the current directory
home="$test_root/relative_config"
mkdir -p "$home/.woche"
printf 'WOCHE_DIR=notes\n' > "$home/.woche/config"
output=$(cd "$test_root/cwd" && woche_in "$home" -- create)
if [ -e "$home/notes/$current_week.md" ]; then
    echo "Test relative WOCHE_DIR in the config is relative to HOME: PASSED"
else
    echo "Test relative WOCHE_DIR in the config is relative to HOME: FAILED"
    exit 1
fi

# Test ~user is expanded (as root this would create the directory: skip)
if [ "$(id -u)" != 0 ]; then
    output=$(woche_in "$home" -- config dir "~root/woche_test_never_created" 2> /dev/null)
    root_home=$(getent passwd root | cut -d: -f6)
    assert_contains "~user is expanded" "$output" "$root_home/woche_test_never_created"
fi

# --- v1.6: task addresses and the week file format ---

home="$test_root/parser"
files="$test_root/parser_files"
woche_p() {
    woche_in "$home" WOCHE_DIR="$files" "$@"
}
week_file="$files/$current_week.md"

output=$(woche_p -- create)
output=$(woche_p -- mon "first")
output=$(woche_p -- mon "second")
output=$(woche_p -- tue "on tuesday")

# Test new tasks go to the end of the day
monday_block=$(sed -n '/^# Monday,/,/^# Tuesday,/p' "$week_file")
assert_contains "new tasks go to the end of the day" "$monday_block" "- first
- second"

# Test 'show' prints the task addresses
output=$(woche_p -- show)
assert_contains "'show' prints mon.1" "$output" "- first (mon.1)"
assert_contains "'show' prints mon.2" "$output" "- second (mon.2)"
assert_contains "'show' numbers each day from 1" "$output" "- on tuesday (tue.1)"

# Test 'done <day> <n>'
output=$(woche_p -- "done" mon 2)
assert_contains "'done mon 2'" "$output" "Task mon.2 marked as done."
assert_contains "'done mon 2' changes the right task" "$(cat "$week_file")" "- [x] second"

# Test 'done' on a finished task
output=$(woche_p -- "done" mon.2)
assert_contains "'done mon.2' on a finished task" "$output" "Task mon.2 is already done."

# Test 'edit' keeps a finished task finished and keeps special characters
output=$(woche_p -- edit mon 2 'second & /done\ $HOME')
assert_contains "'edit mon 2'" "$output" "Task mon.2 edited."
assert_contains "'edit' keeps [x] and the text as typed" "$(cat "$week_file")" '- [x] second & /done\ $HOME'

# Test a task that does not exist
output=$(woche_p -- "done" mon 9)
assert_contains "missing task" "$output" "Error: Task mon.9 does not exist."

# Test a missing task number
output=$(woche_p -- "done" mon)
assert_contains "missing task number" "$output" "Error: Tell which task"

# Test an invalid day in an address
output=$(woche_p -- "done" xyz 1)
assert_contains "invalid day in an address" "$output" "Error: Invalid day 'xyz'."

# Test a line number that is not a task cannot be edited (it used to overwrite headers)
output=$(woche_p -- edit 1 "oops")
assert_contains "'edit' on a header line" "$output" "Error: Line 1 is not a task."
assert_contains "header kept" "$(head -n 1 "$week_file")" "# Monday,"
output=$(woche_p -- "done" 4)
assert_contains "'done' on an empty line" "$output" "Error: Line 4 is not a task."

# Test 'delete <day> <n>'
output=$(echo "y" | woche_p -- delete mon 1)
assert_contains "'delete mon 1'" "$output" "Task mon.1 deleted."
if grep -q "^- first$" "$week_file"; then
    echo "Test 'delete mon 1' removes the task: FAILED"
    exit 1
else
    echo "Test 'delete mon 1' removes the task: PASSED"
fi

# Test 'search' is literal, not a regex
output=$(woche_p -- tue "costs 1+1 [draft]")
output=$(woche_p -- search "1+1 [draft]")
assert_contains "'search' finds literal text" "$output" "$current_week.md:"
output=$(woche_p -- search "c.sts")
if [[ "$output" == *"costs"* ]]; then
    echo "Test 'search' does not treat . as a wildcard: FAILED"
    exit 1
else
    echo "Test 'search' does not treat . as a wildcard: PASSED"
fi

# Test 'open' without EDITOR names the variable
output=$(woche_p EDITOR= -- open)
assert_contains "'open' without EDITOR" "$output" "Error: The EDITOR environment variable is not set."

# Test addresses in a German file, with German or English day names
home_de="$test_root/parser_de"
files_de="$test_root/parser_de_files"
output=$(woche_in "$home_de" WOCHE_DIR="$files_de" WOCHE_LANGUAGE=de -- create)
output=$(woche_in "$home_de" WOCHE_DIR="$files_de" WOCHE_LANGUAGE=de -- mont "erste")
output=$(woche_in "$home_de" WOCHE_DIR="$files_de" WOCHE_LANGUAGE=de -- show)
assert_contains "'show' in a German file" "$output" "- erste (mont.1)"
assert_contains "German legend" "$output" "Current week: mont ("
output=$(woche_in "$home_de" WOCHE_DIR="$files_de" WOCHE_LANGUAGE=de -- "done" mon 1)
assert_contains "English address in a German file" "$output" "Task mont.1 marked as done."

# Test a week across the new year gets the right dates
output=$(woche_p WOCHE_WEEK=261228 -- create)
new_year=$(cat "$files/261228.md")
assert_contains "week across the new year: Thursday" "$new_year" "# Thursday, 31/12"
assert_contains "week across the new year: Friday" "$new_year" "# Friday, 1/1"
assert_contains "week across the new year: Sunday" "$new_year" "# Sunday, 3/1"

# Test WOCHE_WEEK adds to that week
output=$(woche_p WOCHE_WEEK=261228 -- fri "new year")
assert_contains "WOCHE_WEEK adds to that week" "$(cat "$files/261228.md")" "# Friday, 1/1
- new year"

# Test WOCHE_WEEK must be a Monday
output=$(woche_p WOCHE_WEEK=261229 -- show)
assert_contains "WOCHE_WEEK must be a Monday" "$output" "Error: WOCHE_WEEK must be the Monday"

# Test a week across a month end
output=$(woche_p WOCHE_WEEK=261026 -- create)
assert_contains "week across a month end" "$(cat "$files/261026.md")" "# Sunday, 1/11"

# Test unquoted text is refused instead of cut to its first word
output=$(woche_p -- mon "keep me")
output=$(woche_p -- edit mon.1 Call mom)
assert_contains "'edit' with unquoted text" "$output" "Error: Too many arguments."
output=$(woche_p -- edit mon 1 Call mom)
assert_contains "'edit <day> <n>' with unquoted text" "$output" "Error: Too many arguments."
line_keep=$(grep -n "^- keep me$" "$week_file" | cut -d: -f1)
output=$(woche_p -- edit "$line_keep" Buy milk)
assert_contains "'edit <line>' with unquoted text" "$output" "Error: Too many arguments."
output=$(woche_p -- mon buy milk)
assert_contains "adding unquoted text" "$output" "Error: Too many arguments."
output=$(woche_p -- today buy milk)
assert_contains "'today' with unquoted text" "$output" "Error: Too many arguments."
output=$(woche_p -- search two words)
assert_contains "'search' with unquoted text" "$output" "Error: Too many arguments."
output=$(woche_p -- "done" mon 1 extra)
assert_contains "'done' with an extra argument" "$output" "Error: Too many arguments."
if grep -q "^- keep me$" "$week_file" && ! grep -q "^- buy$" "$week_file"; then
    echo "Test unquoted text leaves the file alone: PASSED"
else
    echo "Test unquoted text leaves the file alone: FAILED"
    exit 1
fi

# Test task number 0 and absurd numbers fail cleanly
output=$(woche_p -- "done" mon 0 2>&1)
assert_contains "task number 0" "$output" "Error: Task mon.0 does not exist."
output=$(woche_p -- "done" 0 2>&1)
assert_contains "line number 0" "$output" "Error: Line 0 is not a task."
output=$(woche_p -- "done" mon 99999999999999999999 2>&1)
if [[ "$output" == *"does not exist"* ]] && [[ "$output" != *"expression"* ]]; then
    echo "Test huge task number: PASSED"
else
    echo "Test huge task number: FAILED"
    exit 1
fi
output=$(woche_p -- "done" mon 02 2>&1)
assert_contains "leading zeros" "$output" "Task mon.2"

# Test a new task goes after the indented lines of the last task
home_sub="$test_root/sub"
files_sub="$test_root/sub_files"
output=$(woche_in "$home_sub" WOCHE_DIR="$files_sub" -- create)
output=$(woche_in "$home_sub" WOCHE_DIR="$files_sub" -- mon "parent")
sed -i 's/^- parent$/- parent\n  - child/' "$files_sub/$current_week.md"
output=$(woche_in "$home_sub" WOCHE_DIR="$files_sub" -- mon "next")
assert_contains "new task after indented lines" "$(cat "$files_sub/$current_week.md")" "- parent
  - child
- next"

# Test 'done' on an unchecked box and 'edit' with [x] in the text
output=$(woche_in "$home_sub" WOCHE_DIR="$files_sub" -- mon "[ ] boxed")
output=$(woche_in "$home_sub" WOCHE_DIR="$files_sub" -- "done" mon 3)
assert_contains "'done' on '- [ ]'" "$(cat "$files_sub/$current_week.md")" "- [x] boxed"
output=$(woche_in "$home_sub" WOCHE_DIR="$files_sub" -- edit mon 3 "[x] boxed again")
if grep -q '^- \[x\] boxed again$' "$files_sub/$current_week.md"; then
    echo "Test 'edit' does not double [x]: PASSED"
else
    echo "Test 'edit' does not double [x]: FAILED"
    exit 1
fi

# Test CRLF files show without carriage returns
sed -i 's/$/\r/' "$files_sub/$current_week.md"
output=$(woche_in "$home_sub" WOCHE_DIR="$files_sub" -- show)
if [[ "$output" == *$'\r'* ]]; then
    echo "Test CRLF file shows without carriage returns: FAILED"
    exit 1
else
    echo "Test CRLF file shows without carriage returns: PASSED"
fi

# Test a write failure is reported, not hidden behind a success message
if [ "$(id -u)" != 0 ]; then
    chmod a-w "$week_file"
    output=$(woche_p -- edit mon 1 "not written" 2>&1)
    chmod u+w "$week_file"
    assert_contains "write failure is reported" "$output" "Error: Could not write"
fi
