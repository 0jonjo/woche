#!/usr/bin/env bash

# The path to create and edit the file
path_to_files="/home/$(whoami)/"

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

woche_array=($mon $die $mit $don $fre $sam $son)
week_array=($mond $tue $wed $thu $fri $sat $sun)

woche_array_string=("mont" "die" "mit" "don" "fre" "sam" "son")
week_array_string=("mon" "tue" "wed" "thu" "fri" "sat" "sun")
options=("create" "show" "help" "delete" "edit" "all")

# Create an array that is options + woche_array name of variables as strings
options_to_check=("${options[@]}" "${week_array_string[@]}")
