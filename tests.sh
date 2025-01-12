#!/usr/bin/env bash

source functions.sh
source variables.sh

woche_script_path="./woche.sh"

# Store original path_to_files in variables.sh
original_path_to_files="$path_to_files"

# Ensure path_to_files is set to the test directory in variables.sh
sed -i 's|^path_to_files=.*|path_to_files="/tmp/"|' variables.sh
source variables.sh

current_week
file=$current_week

check_test_result() {
    if [[ "$output" == *"FAILED"* ]]; then
        exit 1
    fi
}

delete_file() {
    cd "$path_to_files" > /dev/null || exit
    rm -f "$current_week.md"
    cd - > /dev/null || exit
}

delete_file

# Test with more than 3 arguments
output=$("$woche_script_path" mon "Test task" "Argument" "Extra argument")
if [[ "$output" == *"tips: woche.sh"* ]]; then
    echo "Test 'more than 3 arguments' command: PASSED"
else
    echo "Test 'more than 3 arguments' command: FAILED"
fi
check_test_result

#  Test if the file do not exists - show command
output=$("$woche_script_path" show)
if [[ "$output" == *"Error: The file"* ]]; then
    echo "Test if the file do not exists - show command: PASSED"
else
    echo "Test if the file do not exists - show command: FAILED"
fi
check_test_result

# Test if the file do not exists - delete command
output=$("$woche_script_path" delete 2)
if [[ "$output" == *"Error: The file"* ]]; then
    echo "Test if the file do not exists - delete command: PASSED"
else
    echo "Test if the file do not exists- delete command: FAILED"
fi
check_test_result

# Test if the file do not exists - edit command
output=$("$woche_script_path" edit 2 "New task")
if [[ "$output" == *"Error: The file"* ]]; then
    echo "Test if the file do not exists - edit command: PASSED"
else
    echo "Test if the file do not exists - edit command: FAILED"
fi
check_test_result

# Test invalid command
output=$("$woche_script_path" invalid)
if [[ "$output" == *"tips: woche.sh"* ]]; then
    echo "Test invalid command: PASSED"
else
    echo "Test invalid command: FAILED"
fi
check_test_result

# Test the 'help' command
output=$("$woche_script_path" help)
if [[ "$output" == *"tips: woche.sh"* ]]; then
    echo "Test 'help' command: PASSED"
else
    echo "Test 'help' command: FAILED"
fi
check_test_result

# Test the 'create' command
output=$("$woche_script_path" create)
if [[ "$output" == *"The file"*"has been created."* ]]; then
    echo "Test 'create' command: PASSED"
else
    echo "Test 'create' command: FAILED"
fi
check_test_result

# Test the 'create' command when the file already exists
output=$("$woche_script_path" create)
if [[ "$output" == *"The file"*"already exists."* ]]; then
    echo "Test 'create' command when the file already exists: PASSED"
else
    echo "Test 'create' command when the file already exists: FAILED"
fi
check_test_result

## Check if the file is created on last test
cd "$path_to_files" > /dev/null || exit
if [ ! -e "$file.md" ]; then
    echo "Error: The file $file.md does not exist."
    exit 1
fi
cd - > /dev/null || exit

# Check if the # Monday was added to the file
cd "$path_to_files" > /dev/null || exit
if [ -z "$(sed -n "/# $mon/ p" "$file.md")" ]; then
    echo "Error: The day of the week is not written in the file."
    exit 1
fi
cd - > /dev/null || exit

# Test the last command
cd "$path_to_files" > /dev/null || exit
last_week=$(date -d "$current_week - 7 days" "+%y%m%d")
cp "$file.md" "$last_week.md"
cd - > /dev/null || exit

output=$("$woche_script_path" show last)
if [[ "$output" == *"Week starts on"* ]]; then
    echo "Test 'last week' command: PASSED"
else
    echo "Test 'last week' command: FAILED"
fi
check_test_result

# Test the all command
output=$("$woche_script_path" all)
if [[ "$output" == "All markdown files in $path_to_files:"* ]]; then
    echo "Test 'all' command: PASSED"
else
    echo "Test 'all' command: FAILED"
fi
check_test_result

# Test add task to a day command
output=$("$woche_script_path" mon "Test task")
if [[ "$output" == *"Task 'Test task' added to"* ]]; then
    echo "Test 'add task to a day' command: PASSED"
else
    echo "Test 'add task to a day' command: FAILED"
fi
check_test_result

## Check if the task is added on last test
cd "$path_to_files" > /dev/null || exit
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
fi
check_test_result

# Test edit command with punctituation
output=$("$woche_script_path" edit 2 "New task ,.!@")
if [[ "$output" == *"Line 2 edited."* ]]; then
    echo "Test 'edit' command: PASSED"
else
    echo "Test 'edit' command: FAILED"
fi

## Check if the task is edited on last test
cd "$path_to_files" > /dev/null || exit
if ! sed -n "2 p" "$file.md" | grep -q "New task ,.!@"; then
    echo "Error: Task has not been edited."
    exit 1
fi
cd - > /dev/null || exit

# Test show command
output=$("$woche_script_path" show)
if [[ "$output" == *"Week starts on"* ]]; then
    echo "Test 'show' command: PASSED"
else
    echo "Test 'show' command: FAILED"
fi
check_test_result

# Test delete command
output=$("$woche_script_path" delete 2)
if [[ "$output" == *"Line 2 deleted."* ]]; then
    echo "Test 'delete' command: PASSED"
else
    echo "Test 'delete' command: FAILED"
fi
check_test_result

delete_file

# Revert path_to_files to its original value in variables.sh
sed -i "s|^path_to_files=.*|path_to_files=""$original_path_to_files""|" variables.sh
source variables.sh