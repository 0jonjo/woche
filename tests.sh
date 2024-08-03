#!/usr/bin/env bash

source functions.sh
source variables.sh

woche_script_path="./woche.sh"

start_day_of_week

check_test_result() {
    if [[ "$output" == *"FAILED"* ]]; then
        exit 1
    fi
}

delete_file() {
    cd "$path_to_files" > /dev/null
    rm -f "$start_day.md"
    cd - > /dev/null
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
cd "$path_to_files" > /dev/null
if [ ! -e "$start_day.md" ]; then
    echo "Error: The file $start_day.md does not exist."
    exit 1
fi
cd - > /dev/null

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
cd "$path_to_files" > /dev/null
if [ -z "$(sed -n "/# $mon/ p" "$start_day.md")" ]; then
    echo "Error: Task has not been added."
    exit 1
fi
cd - > /dev/null

# Test edit command
output=$("$woche_script_path" edit 2 "New task")
if [[ "$output" == *"Line 2 edited."* ]]; then
    echo "Test 'edit' command: PASSED"
else
    echo "Test 'edit' command: FAILED"
fi

## Check if the task is edited on last test
cd "$path_to_files" > /dev/null
if [ -z "$(sed -n "2 p" "$start_day.md" | grep "New task")" ]; then
    echo "Error: Task has not been edited."
    exit 1
fi
cd - > /dev/null

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
