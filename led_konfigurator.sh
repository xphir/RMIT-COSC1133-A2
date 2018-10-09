#!/bin/bash

# -----------------------------------
# Declarations
# ------------------------------------
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

version=0.1
LEDS_FOLDER=/sys/class/leds/

STRING_SELECTED_VALUE=""
STRING_TRIGGER_FILE=""
declare -i INT_SELECTED_FOLDER_ARRAY_NUM
declare -i INT_FOLDER_ARRAY_LENGTH
declare -i INT_TRIGGER_ARRAY_LENGTH
declare -a ARRAY_FOLDER_NAMES
declare -a ARRAY_TRIGGER_NAMES


# -----------------------------------
# Utility Functions
# ------------------------------------
pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

pause_custom(){
    local input=$1
    read -p "$input" fackEnterKey
}



# -----------------------------------
# Task 2: Script launch
# ------------------------------------
main(){
    while true
    do
        main_message
        main_read
    done
}

main_message(){
    printf "\n"
    echo "Welcome to Led_Konfigurator!"
    echo "============================"
    echo "Please select an led to configure:"
    print_folder_array
}

main_read(){
    local limit
    local choice

    INT_FOLDER_ARRAY_LENGTH=${#ARRAY_FOLDER_NAMES[@]}
    let limit=$INT_FOLDER_ARRAY_LENGTH+1

	read -p "Please enter a number (1-$limit) for the led to configure or quit:" choice
	case $choice in
		[1-$INT_FOLDER_ARRAY_LENGTH]) manipulation_menu $choice;;
		$limit) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
}

create_folder_array(){
    for folder in $LEDS_FOLDER*
    do
        folder=${folder%*/}
        ARRAY_FOLDER_NAMES=(${ARRAY_FOLDER_NAMES[@]} "${folder##*/}")
    done
}

print_folder_array(){
    local counter=1
    for FolderName in "${ARRAY_FOLDER_NAMES[@]}"
    do
        echo "$counter. $FolderName"
        ((counter++))
    done
    echo "$counter. Quit"
    echo 
}

# -----------------------------------
# Task 3: LED Manipulation Menu
# ------------------------------------
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
    echo "$STRING_SELECTED_VALUE"
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

get_folder_array_selection(){
    local read_selection=$1
    local counter=1
    for FolderName in "${ARRAY_FOLDER_NAMES[@]}"
    do
        if [ $read_selection -eq $counter ]
        then
            #Note this is global
            STRING_SELECTED_VALUE="$FolderName"

            INT_SELECTED_FOLDER_ARRAY_NUM=$counter
            STRING_TRIGGER_FILE="${LEDS_FOLDER}${FolderName}/trigger"
            return
        fi
        ((counter++))
    done
}

# -----------------------------------
# Task 4:  Turn on and off the led
# ------------------------------------

manipulation_turn_on(){
    local brightness=1

    printf "LED: %s turned on \n" "$STRING_SELECTED_VALUE"
    led_brightness $STRING_SELECTED_VALUE $brightness
    pause
}

manipulation_turn_off(){
    local brightness=0
    printf "LED: %s turned off \n" "$STRING_SELECTED_VALUE"
    led_brightness $STRING_SELECTED_VALUE $brightness
    pause
}

led_triggers() {
   local led=$1
   local trigger=$2

   if [ -z "$trigger" ]; then
       cat "$leds/$led/trigger"
   else
       echo "$trigger" > "$leds/$led/trigger"
   fi
}

led_brightness() {
   local led=$1
   local brightness=$2

   if [ -z "$brightness" ]; then
       cat "${LEDS_FOLDER}${led}/brightness"
   else
       echo "$brightness" > "${LEDS_FOLDER}${led}/brightness"
   fi
}

# -----------------------------------
# Task 5:  Associate LED with a system event
# ------------------------------------

manipulation_associate_system(){
    echo "manipulation_associate_system $STRING_SELECTED_VALUE"
    while true
    do
        associate_system_message
        associate_system_read
    done
}

associate_system_message(){
    printf "\n"
    echo "Associate Led with a system Event"
    echo "================================="
    echo "Available events are:"
    echo "---------------------"
    print_associate_system_array
}

print_associate_system_array(){
    #Line count is 5 to allow the menu headers
    local count=1
    local screen_size=$(tput lines)
    #Screen buffer is how many lines of give before you pause to show more
    local screen_buffer=5

    ARRAY_TRIGGER_NAMES=(`cat "$STRING_TRIGGER_FILE"`)
    INT_TRIGGER_ARRAY_LENGTH=${#ARRAY_TRIGGER_NAMES[@]}

    for trigger in "${ARRAY_TRIGGER_NAMES[@]}"
    do
        printf "%s) %s\n" "$count" "$trigger"
        
        ((count++))
        ((screen_buffer++))
        if [ $screen_buffer -gt $screen_size ]
        then
            pause_custom "Press [Enter] key to show the rest of the options..."
            screen_buffer=5
        fi
    done
    printf "%s) %s\n" "$count" "Quit to previous menu"
}

associate_system_read(){
	local choice
    local limit
    let limit=$INT_TRIGGER_ARRAY_LENGTH+1
	read -p "Please select an option (1-$limit):" choice
    case $choice in
		[1-$INT_TRIGGER_ARRAY_LENGTH]) led_add_trigger $choice;;
		$limit) manipulation_menu $INT_SELECTED_FOLDER_ARRAY_NUM;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
}

led_add_trigger(){
    local int_selected_trigger=$1

    #this is set to -1 because the array starts at 0 not 1
    let int_selected_trigger=$int_selected_trigger-1
    local selected_trigger=${ARRAY_TRIGGER_NAMES[$int_selected_trigger]}
    
    echo "selected_trigger $selected_trigger added to $STRING_SELECTED_VALUE"
    echo "$selected_trigger" > "${LEDS_FOLDER}${STRING_SELECTED_VALUE}/trigger"
}

# -----------------------------------
# Task 6:  Associate LED with the performance of a process
# ------------------------------------

manipulation_process_performance(){

    echo "manipulation_process_performance $STRING_SELECTED_VALUE"
    associate_process_message
    #associate_process_read
}

associate_process_message(){
    printf "\n"
    echo "Associate LED with the performance of a process"
    echo "------------------------------------------------"
}

associate_process_read(){
	local program_choice
    local monitor_choice
    local program_selected
    local count
    local -a process_array
	read -p "Please enter the name of the program to monitor(partial names are ok):" program_choice
    read -p "Do you wish to 1) monitor memory or 2) monitor cpu? [enter memory or cpu]:" monitor_choice
    echo "starting to monitor $program_selected"

    process_array=$(ps aux | grep $program_choice | awk '{print $11}')
    process_array_size=${#process_array[@]}
    echo "process_array_size: $process_array_size"
    if [ ${#process_array[@]} -gt 1 ]
    then
        echo "Name Conflict"
        echo "-------------"
        echo "I have detected a name conflict. Do you want to monitor:"
        for process in $process_array
        do
            printf "%s) %s\n" "$count" "$process"
        ((count++))
        done
    else
        echo "starting to monitor $process_array"
    fi
}


# -----------------------------------
# Task 7: Unassociate an LED with performance monitoring
# ------------------------------------

manipulation_stop_association(){

    echo "manipulation_stop_association $STRING_SELECTED_VALUE"
    pause
}


# ----------------------------------------------
# Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
#trap '' SIGINT SIGQUIT SIGTSTP

# -----------------------------------
# Create array from folder stuct
# ------------------------------------
create_folder_array

# -----------------------------------
# Main function call
# ------------------------------------
main