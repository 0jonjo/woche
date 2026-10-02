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
        exit 1
        echo "  expected to contain: $3"
        echo "  got: $2"
        exit 1
    fi
}

# Test with more than 3 arguments
output=$("$woche_script_path" mon "Test task" "Argument" "Extra argument")
if [[ "$output" == *"Woche - Weekly Task Manager"* ]]; then
    echo "Test 'more than 3 arguments' command: PASSED"
else
    echo "Test 'more than 3 arguments' command: FAILED"
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
if [ -z "$(sed -n "/# $mon/ p" "$file.md")" ]; then
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
if [[ "$output" == *"Task on line $line_to_mark_done marked as done."* ]]; then
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
assert_contains "v1.5 config without WOCHE_DIR prints a hint" "$output" "WOCHE_DIR is not set in"

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
