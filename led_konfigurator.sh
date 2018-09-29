#!/bin/bash

version=0.1
LEDS_FOLDER=/sys/class/leds/

SELECTED_VALUE=""
TRIGGER_FILE=""
declare -i SELECTED_ARRAY_NUM
declare -a ARRAY_FOLDER_NAMES
declare -a ARRAY_TRIGGER_NAMES

welcome_message(){
    printf "\n"
    echo "Welcome to Led_Konfigurator!"
    echo "============================"
    echo "Please select an led to configure:"
    print_folder_array
}

create_folder_array(){
    for folder in $LEDS_FOLDER*
    do
        folder=${folder%*/}
        ARRAY_FOLDER_NAMES=(${ARRAY_FOLDER_NAMES[@]} "${folder##*/}")
    done
}

print_folder_array(){
    FOLDER_COUNTER=1
    for FolderName in "${ARRAY_FOLDER_NAMES[@]}"
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
    local read_selection=$1
    #Set the global variables to the selected menu choice
    get_folder_array_selection $read_selection

    while true
    do
        manipulation_message
        manipulation_read
    done
}

manipulation_message(){
    printf "\n"
    echo "$SELECTED_VALUE"
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
    local choice
	read -p "Please enter a number (1-6) for your choice:" choice
    case $choice in
        1) manipulation_turn_on;;
        2) manipulation_turn_off;;
        3) manipulation_associate_system;;
        4) manipulation_process_performance;;
        5) manipulation_stop_association;;
        6) main;;
        *) echo -e "${RED}Error...${STD}" && sleep 2
    esac
}

manipulation_turn_on(){
    local brightness=1

    echo "manipulation_turn_on $SELECTED_VALUE"
    led_brightness $SELECTED_VALUE $brightness
    pause
}

manipulation_turn_off(){
    local brightness=0

    echo "manipulation_turn_on $SELECTED_VALUE"
    led_brightness $SELECTED_VALUE $brightness
    pause
}

manipulation_associate_system(){
    echo "manipulation_associate_system $1"
    pause
}

manipulation_process_performance(){

    echo "manipulation_process_performance $SELECTED_VALUE"
    pause
}

manipulation_stop_association(){

    echo "manipulation_stop_association $SELECTED_VALUE"
    pause
}

get_folder_array_selection(){
    local read_selection=$1
    local counter=1
    for FolderName in "${ARRAY_FOLDER_NAMES[@]}"
    do
        if [ $read_selection -eq $counter ]
        then
            #Note this is global
            SELECTED_VALUE="$FolderName"
            SELECTED_ARRAY_NUM=$counter
            TRIGGER_FILE="${LEDS_FOLDER}${FolderName}/trigger"
            return
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

main(){
    while true
    do
        welcome_message
        read_options
    done
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
main