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
declare -a ARRAY_PROCESS_GREP

declare MONITOR_SCRIPT_PATH="./monitor.sh"
declare MONITOR_LED_TYPE="led0"
declare MONITOR_SCRIPT_PID
declare -i MONITOR_SCRIPT_RUNNING=0

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

associate_process_message(){
    printf "\n"
    echo "Associate LED with the performance of a process"
    echo "------------------------------------------------"
}

associate_process_read(){
	local program_choice

    while true
    do
        read -p "Please enter the name of the program to monitor(partial names are ok):" program_choice
        associate_process_read_type $program_choice
    done
}

associate_process_read_type(){
    local program_choice=$1
	local monitor_choice
	read -p "Do you wish to 1) monitor memory or 2) monitor cpu? [enter memory or cpu]:" monitor_choice
    case $monitor_choice in
		[1-2]) associate_process_search $program_choice $monitor_choice;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
}

associate_process_search(){
    local program_choice=$1
    local monitor_choice=$2
    local -i process_array_size
    local -i result_type

    ARRAY_PROCESS_GREP=($(ps aux | grep $program_choice |  grep -v grep | awk '{print $2}'))
    process_array_size=${#ARRAY_PROCESS_GREP[@]}

    #Get result_type
    if [ $process_array_size -gt 1 ]
    then
        associate_process_print_array
        let result_type=1
    elif [ ${#ARRAY_PROCESS_GREP[@]} -eq 1 ]
    then
        let result_type=2
    else
        let result_type=3
    fi

    #Process result_type
    if [ $result_type -eq 1 ]
    then
        while true
        do
            associate_process_search_select $monitor_choice
        done
    elif [ $result_type -eq 2 ]
    then
        associate_process_launcher 0 $monitor_choice
    elif [ $result_type -eq 3 ]
    then
        echo "No matches found... returning"
    else
        echo "This should never happen"
    fi
}

associate_process_print_array(){
    local -i count=0
    local -i array_size=${#ARRAY_PROCESS_GREP[@]}
    local pid_value

    echo "Name Conflict"
    echo "-------------"
    echo "I have detected a name conflict. Do you want to monitor:"
    for process in ${ARRAY_PROCESS_GREP[@]}
    do
        pid_value=$(ps -p $process -o cmd=)
        printf "%s) %s\n" "$count" "$pid_value"
        ((count++))
    done
    printf "%s) %s\n" "$count" "return"
}

associate_process_search_select(){
    local -i array_size=${#ARRAY_PROCESS_GREP[@]}
    local -i monitor_choice=$1
    local array_selection
    read -p "Please enter a number (1-$array_size) for your choice:" array_selection
    case $array_selection in
        [0-$((array_size -1))]) associate_process_launcher $array_selection $monitor_choice;;
        $array_size) manipulation_menu;;
        *) echo -e "${RED}Error...${STD}" && sleep 2
    esac
}

associate_process_launcher(){
    local -i array_selection=$1
    local -i monitor_choice=$2
    local monitor_type
    local -i array_size=${#ARRAY_PROCESS_GREP[@]}
    local pid
    local pid_value

    pid=${ARRAY_PROCESS_GREP[$array_selection]}
    pid_value=$(ps -p $pid -o cmd=)
    
    if [ $MONITOR_SCRIPT_RUNNING -eq 1 ]
    then
        manipulation_stop_association
    fi

    echo "Starting to monitor $monitor_type for $pid_value"
    echo "Launching monitor script: $MONITOR_SCRIPT_PATH PID: $pid Monitor Type: $monitor_choice LED#: $MONITOR_LED_TYPE"
    nohup $MONITOR_SCRIPT_PATH -p $pid -t $monitor_choice -l $MONITOR_LED_TYPE &>/dev/null &
    MONITOR_SCRIPT_PID=$!
    MONITOR_SCRIPT_RUNNING=1
    echo "Monitor script launched with PID: $MONITOR_SCRIPT_PID"
    sleep 5

    manipulation_stop_association

    manipulation_menu
}

# -----------------------------------
# Task 7: Unassociate an LED with performance monitoring
# ------------------------------------

manipulation_stop_association(){
    if [ -e /proc/${MONITOR_SCRIPT_PID} -a /proc/${MONITOR_SCRIPT_PID}/exe ]
    then
        disown $MONITOR_SCRIPT_PID
        kill -SIGTERM $MONITOR_SCRIPT_PID
        sleep 0.1
        led_brightness $MONITOR_LED_TYPE 0
        MONITOR_SCRIPT_RUNNING=0
        echo "Perforance monitor script (PID:$MONITOR_SCRIPT_PID) has been stoped"
    else
        echo "No script running..."
        MONITOR_SCRIPT_RUNNING=0
    fi
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