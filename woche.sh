#!/bin/bash

tips() {
    echo "tips: woche.sh"
    echo "create: a new markdown file for the current week"
    echo "mon, die, mit, don, fre, sam, son: add a task to the day of the week (in German)"
}

# Check the number of arguments
if [ "$#" -gt 2 ]; then
    tips
    exit 1
fi

# Find the start_day (monday) of the current week, not the next week
start_day=$(date -d "last monday" "+%y%m%d")
# If monday is  today, set the current monday
if [ "$(date "+%A")" == "Monday" ]; then
    start_day=$(date "+%y%m%d")
fi

# The path to create and edit the file
path="/home/$(whoami)/"
cd "$path"

day=""
task="$2"

# Days of the week in German and English
mon="Montag"
die="Dienstag"
mit="Mittwoch"
don="Donnerstag"
fre="Freitag"
sam="Samstag"
son="Sonntag"

mond="Monday"
tue="Tuesday"
wed="Wednesday"
thu="Thursday"
fri="Friday"
sat="Saturday"
sun="Sunday"

# Array of the days of the week
woche_array=($mon $die $mit $don $fre $sam $son)
week_array=($mond $tue $wed $thu $fri $sat $sun)

woche_array_string=("mon" "die" "mit" "don" "fre" "sam" "son")
options=("create" "show" "help")

# Create an array that is options + woche_array name of variables as strings
options_to_check=("${options[@]}" "${woche_array_string[@]}")

# Check if $1 is in the options to check
if [[ ! " ${options_to_check[@]} " =~ " $1 " ]]; then
    tips
    exit 1
fi

case $1 in
    create)
        if [ -e "$start_day.md" ]; then
            echo "The file $start_day.md already exists."
            exit 1
        fi
        for i in "${woche_array[@]}"; do
            printf "# %s\n\n" "$i" >> "$start_day.md"
        done
        echo "The file $start_day.md has been created."
        exit 0
        ;;
    show)
        if [ ! -e "$start_day.md" ]; then
            echo "The file $start_day.md does not exist."
            exit 1
        fi
        printf "Week starts in $start_day.\n\n"
        cat "$start_day.md"
        exit 0
        ;;
    help)
        tips
        exit 0
        ;;
    *)
        day=$(eval echo \$$1)
        sed -i "/$day/ a\\- $task" "$start_day.md"
        echo "Task '$task' added to $day."
        exit 0
        ;;
esac

