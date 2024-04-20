#!/bin/bash

# Path to the woche.sh script
woche_script_path="./woche.sh"

check_test_result() {
    if [[ "$output" == *"FAILED"* ]]; then
        exit 1
    fi
}

# Test with more than 2 arguments
output=$("$woche_script_path" mon "Test task" "Extra argument")
if [[ "$output" == *"tips: woche.sh"* ]]; then
    echo "Test 'more than 2 arguments' command: PASSED"
else
    echo "Test 'more than 2 arguments' command: FAILED"
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

# Test add task to a day command
output=$("$woche_script_path" mon "Test task")
if [[ "$output" == *"Task 'Test task' added to"* ]]; then
    echo "Test 'add task to a day' command: PASSED"
else
    echo "Test 'add task to a day' command: FAILED"
fi
check_test_result

