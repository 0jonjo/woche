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

# Find the start_day of the current week
start_day=$(date -d "mon" +%y%m%d)

# The path to create and edit the file
path="/home/$(whoami)/"
cd "$path"

day=""
task="$2"

# Days of the week in German and English
montag="Montag"
dienstag="Dienstag"
mittwoch="Mittwoch"
donnerstag="Donnerstag"
freitag="Freitag"
samstag="Samstag"
sonntag="Sonntag"

monday="Monday"
tuesday="Tuesday"
wednesday="Wednesday"
thursday="Thursday"
friday="Friday"
saturday="Saturday"
sunday="Sunday"

# Array of the days of the week
woche_array=($montag $dienstag $mittwoch $donnerstag $freitag $samstag $sonntag)
week_array=($monday $tuesday $wednesday $thursday $friday $saturday $sunday)

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
esac

case $1 in
    mon)
        day=$montag
        ;;
    die)
        day=$dienstag
        ;;
    mit)
        day=$mittwoch
        ;;
    don)
        day=$donnerstag
        ;;
    fre)
        day=$freitag
        ;;
    sam)
        day=$samstag
        ;;
    son)
        day=$sonntag
        ;;
    *)
        tips
        exit 1
        ;;
esac

sed -i "/$day/ a\\- $task" "$start_day.md"
echo "Task '$task' added to $day."
exit 0