#!/usr/bin/env bash

# The path to create and edit the file
path_to_files="/home/$(whoami)/"

# Days of the week in German and English
export mont="Montag"
export die="Dienstag"
export mit="Mittwoch"
export don="Donnerstag"
export fre="Freitag"
export sam="Samstag"
export son="Sonntag"

export mon="Monday"
export tue="Tuesday"
export wed="Wednesday"
export thu="Thursday"
export fri="Friday"
export sat="Saturday"
export sun="Sunday"

export woche_array=("$mont" "$die" "$mit" "$don" "$fre" "$sam" "$son")
export week_array=("$mon" "$tue" "$wed" "$thu" "$fri" "$sat" "$sun")

export woche_array_string=("mont" "die" "mit" "don" "fre" "sam" "son")
export week_array_string=("mon" "tue" "wed" "thu" "fri" "sat" "sun")
export options=("create" "show" "help" "delete" "edit" "all")

# Create an array that is options + woche_array name of variables as strings
export options_to_check=("${options[@]}" "${week_array_string[@]}")
