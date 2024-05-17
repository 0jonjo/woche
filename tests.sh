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
    cd "$path"
    rm -f "$start_day.md"
    cd -
}

delete_file

# Test with more than 3 arguments
output=$("$woche_script_path" mont "Test task" "Argument" "Extra argument")
if [[ "$output" == *"tips: woche.sh"* ]]; then
    echo "Test 'more than 3 arguments' command: PASSED"
else
    echo "Test 'more than 3 arguments' command: FAILED"
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

# Test add task to a day command
output=$("$woche_script_path" mon "Test task")
if [[ "$output" == *"Task 'Test task' added to"* ]]; then
    echo "Test 'add task to a day' command: PASSED"
else
    echo "Test 'add task to a day' command: FAILED"
fi
check_test_result

# Test edit command
output=$("$woche_script_path" edit 2 "New task")
if [[ "$output" == *"Line 2 edited."* ]]; then
    echo "Test 'edit' command: PASSED"
else
    echo "Test 'edit' command: FAILED"
fi

# Test show command
output=$("$woche_script_path" show)
if [[ "$output" == *"Week starts in"* ]]; then
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

delete_file
