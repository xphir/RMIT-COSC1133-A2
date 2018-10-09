#!/bin/bash

manipulation_process_performance(){
    associate_process_message
    associate_process_read
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
    #read -p "Do you wish to 1) monitor memory or 2) monitor cpu? [enter memory or cpu]:" monitor_choice
    #echo "starting to monitor $program_selected"

    process_array=$(ps aux | grep $program_choice | awk '{print $11}')
    process_array_size=${#process_array[@]}
    
    echo "process_array_size: $process_array_size"
    if [ ${#process_array[@]} -gt 2 ]
    then
        echo "Name Conflict"
        echo "-------------"
        echo "I have detected a name conflict. Do you want to monitor:"
        for process in $process_array
        do
            if [$count -ne $process_array_size]
            then
                printf "%s) %s\n" "$count" "$process"
            fi
            ((count++))
        done
    elif [ ${#process_array[@]} -eq 2 ]
    then
        echo "starting to monitor ${process_array[1]}"
    else
        echo "no matches"
    fi
}

manipulation_process_performance