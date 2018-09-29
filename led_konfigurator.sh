#!/bin/bash

version=0.1
LEDS_FOLDER=/sys/class/leds/

declare -a arrFolderNames

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
    FOLDER_COUNTER=1
    for FolderName in "${arrFolderNames[@]}"
    do
        echo "$FOLDER_COUNTER. $FolderName"
        ((FOLDER_COUNTER++))
    done
    echo "$FOLDER_COUNTER. Quit"
    echo 
}

pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

manipulation_menu(){
    local LOOP=0
    while [ $LOOP -eq 0 ]
    do
        manipulation_message $1
        LOOP=$(manipulation_read $1)
    done
}

manipulation_message(){
    #Find the selected folder
    local counter=1
    for FolderName in "${arrFolderNames[@]}"
    do
        if [ $1 -eq $counter ]
        then
            SELECTED_ITEM=$FolderName
        fi
        ((counter++))
    done

    #Print the message
    echo "$SELECTED_ITEM"
    echo "=========="
    echo "What would you like to do with this led?"
    echo "1) turn on"
    echo "2) turn off"
    echo "3) associate with a system event"
    echo "4) associate with the performance of a process"
    echo "5) stop association with a process’ performance"
    echo "6) quit to main menu"
}
manipulation_read(){
}
}
    pause
}

get_folder_array_selection(){
    local counter=1
    for FolderName in "${arrFolderNames[@]}"
    do
        if [ $1 -eq $counter ]
        then
            return $FolderName
        fi
        ((counter++))
    done
}

read_options(){
    let END_CASE=$FOLDER_COUNTER-1
	local choice
	read -p "Please enter a number (1-$FOLDER_COUNTER) for the led to configure or quit:" choice
	case $choice in
		[1-$END_CASE]*) manipulation_menu $choice;;
		$FOLDER_COUNTER) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
}

# ----------------------------------------------
# Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
trap '' SIGINT SIGQUIT SIGTSTP

# -----------------------------------
# Create array from folder stuct
# ------------------------------------
create_folder_array

# -----------------------------------
# Main logic - infinite loop
# ------------------------------------
while true
do
	welcome_message
	read_options
done