#!/bin/bash

version=0.1
LEDS_FOLDER=/sys/class/leds/
declare -a arrFolderNames

main() {
    create_folder_array
    welcome_message
}

welcome_message(){
    echo "Welcome to Led_Konfigurator!"
    echo "============================"
    echo "Please select an led to configure:"
    print_folder_array
}

create_folder_array(){
    for folder in $LEDS_FOLDER*
    do
        folder=${folder%*/}
        arrFolderNames=(${arrFolderNames[@]} "${folder##*/}")
    done
}

print_folder_array(){
    COUNTER=1
    for FolderName in "${arrFolderNames[@]}"
    do
        echo "$COUNTER. $FolderName"
        ((COUNTER++))
    done
    echo "$COUNTER. Quit"
    echo "Please enter a number (1-$COUNTER) for the led to configure or quit:"
}

main $@
exit 0