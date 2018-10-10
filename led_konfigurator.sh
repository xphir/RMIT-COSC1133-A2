#!/bin/bash

# -----------------------------------
# Declarations
# ------------------------------------

#This checks the script is running as root
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

version=1
#The LEDs folder
LEDS_FOLDER=/sys/class/leds/

#The current selected LED
STRING_SELECTED_VALUE=""
#The current selected trigger
STRING_TRIGGER_FILE=""
#The current selected folder array + releated folder array info
declare -a ARRAY_FOLDER_NAMES
declare -i INT_SELECTED_FOLDER_ARRAY_NUM
declare -i INT_FOLDER_ARRAY_LENGTH

#The current selected trigger array + releated trigger array info
declare -i INT_TRIGGER_ARRAY_LENGTH
declare -a ARRAY_TRIGGER_NAMES

#The array of the processes search
declare -a ARRAY_PROCESS_GREP

#The external script information
declare MONITOR_SCRIPT_PATH="./monitor.sh"
declare MONITOR_SCRIPT_PID
declare -i MONITOR_SCRIPT_RUNNING=0

# -----------------------------------
# Utility Functions
# ------------------------------------

#This function is a generic pause
pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

#this function is a custom pause
pause_custom(){
    local input=$1
    read -p "$input" fackEnterKey
}



# -----------------------------------
# Task 2: Script launch
# ------------------------------------

#This is the main function that calls the sub functions
main(){
    while true
    do
        main_message
        main_read
    done
}

#This function prints the menu
main_message(){
    printf "\n"
    echo "Welcome to Led_Konfigurator!"
    echo "============================"
    echo "Please select an led to configure:"
    print_folder_array
}

#This function allows the user to select the folders
main_read(){
    local limit
    local choice

    INT_FOLDER_ARRAY_LENGTH=${#ARRAY_FOLDER_NAMES[@]}
    let limit=$INT_FOLDER_ARRAY_LENGTH+1

	read -p "Please enter a number (1-$limit) for the led to configure or quit:" choice

    if [ $choice -ne 0 -o $choice -eq 0 2>/dev/null ]
    then
        if [ $choice -gt 0 ] && [ $choice -lt $limit ]
        then
            manipulation_menu $choice
        elif [ $choice -eq $limit ]
        then
            exit 0
        else
            echo -e "${RED}Error not a valid option...${STD}" && sleep 2
        fi
    else
        echo -e "${RED}Error input needs to be an integer...${STD}" && sleep 2
    fi
}

#This fucntion gets the contents of the led folder and turns it into an array
create_folder_array(){
    for folder in $LEDS_FOLDER*/
    do
        folder=${folder%*/}
        ARRAY_FOLDER_NAMES=(${ARRAY_FOLDER_NAMES[@]} "${folder##*/}")
    done
}

#This function prints the folders availible to select
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

#This function calls the sub functions
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

#This function prints the menu options
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

#This function gets the users menu selection
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

#This function sets the global variable for the current selected folders
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

#This fucntion turns on the led
manipulation_turn_on(){
    local brightness=1

    printf "LED: %s turned on \n" "$STRING_SELECTED_VALUE"
    led_brightness $STRING_SELECTED_VALUE $brightness
    pause
}

#This fucntion turns off the led
manipulation_turn_off(){
    local brightness=0
    printf "LED: %s turned off \n" "$STRING_SELECTED_VALUE"
    led_brightness $STRING_SELECTED_VALUE $brightness
    pause
}

#This fucntion adds the system event trigger to the led
led_add_trigger(){
    local led=$1
    local int_selected_trigger=$2

    #this is set to -1 because the array starts at 0 not 1
    let int_selected_trigger=$int_selected_trigger-1
    local selected_trigger=${ARRAY_TRIGGER_NAMES[$int_selected_trigger]}
    
    echo "selected_trigger $selected_trigger added to $led"
    echo "$selected_trigger" > "${LEDS_FOLDER}${led}/trigger"
}

#this function turns the led on or off brightness can be 0 to 255
led_brightness() {
   local led=$1
   local brightness=$2
   
   echo "$brightness" > "${LEDS_FOLDER}${led}/brightness"
}

# -----------------------------------
# Task 5:  Associate LED with a system event
# ------------------------------------

#This fucntion calls the subprocesses
manipulation_associate_system(){
    echo "manipulation_associate_system $STRING_SELECTED_VALUE"
    while true
    do
        associate_system_message
        associate_system_read
    done
}

#This fucntion prints the section header
associate_system_message(){
    printf "\n"
    echo "Associate Led with a system Event"
    echo "================================="
    echo "Available events are:"
    echo "---------------------"
    print_associate_system_array
}


#This fucntion prints the system event triggers
#It also does a regex match for [thing] and does a sed replace to thing*
print_associate_system_array(){
    local regex="(\[)([^\[?].*?)(\])"
    local print_value
    #Line count is 5 to allow the menu headers
    local count=1
    local screen_size=$(tput lines)
    #Screen buffer is how many lines of give before you pause to show more
    local screen_buffer=5

    ARRAY_TRIGGER_NAMES=(`cat "$STRING_TRIGGER_FILE"`)
    INT_TRIGGER_ARRAY_LENGTH=${#ARRAY_TRIGGER_NAMES[@]}

    for trigger in "${ARRAY_TRIGGER_NAMES[@]}"
    do
        if [[ $trigger =~ $REGEX ]]; 
        then
            print_value=($(echo $trigger | sed 's/.*\[\([^]]*\)\].*/\1*/g'))
            printf "%s) %s\n" "$count" "$print_value"           
        else
            printf "%s) %s\n" "$count" "$trigger"
        fi

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

#This fucntion allows the user to pick the system event trigger
associate_system_read(){
    local choice
    local limit
    let limit=$INT_TRIGGER_ARRAY_LENGTH+1
   
    read -p "Please select an option (1-$limit):" choice
    #Check if input is an integer or not
    if [ $choice -ne 0 -o $choice -eq 0 2>/dev/null ]
    then
        if [ $choice -gt 0 ] && [ $choice -lt $limit ]
        then
            led_add_trigger $STRING_SELECTED_VALUE $choice
        elif [ $choice -eq $limit ]
        then
            manipulation_menu $INT_SELECTED_FOLDER_ARRAY_NUM
        else
            echo -e "${RED}Error not a valid option...${STD}" && sleep 2
        fi
    else
        echo -e "${RED}Error input needs to be an integer...${STD}" && sleep 2
    fi
}

# -----------------------------------
# Task 6:  Associate LED with the performance of a process
# ------------------------------------

#This fucntion calls the subprocesses
manipulation_process_performance(){
    associate_process_message
    associate_process_read
}

#This fucntion prints the section header
associate_process_message(){
    printf "\n"
    echo "Associate LED with the performance of a process"
    echo "------------------------------------------------"
}

#This fucntion gets the program the user wants to monitor
associate_process_read(){
	local program_choice

    while true
    do
        read -p "Please enter the name of the program to monitor(partial names are ok):" program_choice
        associate_process_read_type $program_choice
    done
}

#This fucntion gets the performance monitor type from the user
associate_process_read_type(){
    local program_choice=$1
	local monitor_choice
	read -p "Do you wish to 1) monitor memory or 2) monitor cpu? [enter memory or cpu]:" monitor_choice
    case $monitor_choice in
		[1-2]) associate_process_search $program_choice $monitor_choice;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
}

#This function processes the program choice and choses which function to call depending on the result size
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

#This function prints the multiple processes when there is multiple process matches
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

#This function is used to pick between multiple processes when there is multiple process matches
associate_process_search_select(){
    local -i array_size=${#ARRAY_PROCESS_GREP[@]}
    local -i monitor_choice=$1
    local choice

    read -p "Please enter a number (1-$array_size) for your choice:" choice
    if [ $choice -ne 0 -o $choice -eq 0 2>/dev/null ]
    then
        if [ $choice -gt -1 ] && [ $choice -lt $array_size ]
        then
            associate_process_launcher $array_selection $monitor_choice
        elif [ $choice -eq $array_size ]
        then
            manipulation_menu $INT_SELECTED_FOLDER_ARRAY_NUM
        else
            echo -e "${RED}Error not a valid option...${STD}" && sleep 2
        fi
    else
        echo -e "${RED}Error input needs to be an integer...${STD}" && sleep 2
    fi
}

#This function launches the performance monitor script
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

    echo "Starting monitor $monitor_type for $pid_value"
    echo "Launching monitor script: $MONITOR_SCRIPT_PATH PID: $pid Monitor Type: $monitor_choice LED#: $STRING_SELECTED_VALUE"

    nohup $MONITOR_SCRIPT_PATH -p $pid -t $monitor_choice -l $STRING_SELECTED_VALUE &>/dev/null &
    MONITOR_SCRIPT_PID=$!
    MONITOR_SCRIPT_RUNNING=1
    echo "Monitor script launched with PID: $MONITOR_SCRIPT_PID"
    pause
    manipulation_menu $INT_SELECTED_FOLDER_ARRAY_NUM
}

# -----------------------------------
# Task 7: Unassociate an LED with performance monitoring
# ------------------------------------

#Stop the performance monitor script
manipulation_stop_association(){
    #Check if any scripts where ever called
    if [ -z "$MONITOR_SCRIPT_PID" ]
    then
        echo "No script running..."
        MONITOR_SCRIPT_RUNNING=0
    #Check if the recorded script PID is currently running then close it
    elif [ -e /proc/${MONITOR_SCRIPT_PID} -a /proc/${MONITOR_SCRIPT_PID}/exe ]
    then
        disown $MONITOR_SCRIPT_PID
        kill -SIGTERM $MONITOR_SCRIPT_PID
        sleep 0.1
        led_brightness $STRING_SELECTED_VALUE 0
        MONITOR_SCRIPT_RUNNING=0
        echo "Perforance monitor script (PID:$MONITOR_SCRIPT_PID) has been stoped"
        pause
    #If the script was called but is no longer running
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