#!/bin/bash
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

PID=""
TYPE=""
LED=""
LEDS_FOLDER=/sys/class/leds/

led_brightness() {
   local brightness=$1
   local led=$2
   echo "$brightness" > "${LEDS_FOLDER}${led}/brightness"
}

monitor(){
    local -i pid=$1
    local monitor_choice=$2
    local led=$3
    local sleep_time=0.1
    local value
    
    
    if [ $monitor_choice -eq 1 ]
    then
        #memory monitor
        value=($(ps -p $pid -u | grep -v grep | awk '{if(NR>1)print $4}'))
    elif [ $monitor_choice -eq 2 ]
    then
        #cpu monitor
        value=($(ps -p $pid -u | grep -v grep | awk '{if(NR>1)print $3}'))
    else
        echo "Wrong Monitor Type... exiting\n"
        exit
    fi
    
    sleep_time=($(awk -v var="$value" 'BEGIN {print 5/var}'))

    echo "Time: $sleep_time"
    led_brightness 255 $led
    sleep $sleep_time
    led_brightness 0 $led
}

monitor_launch(){
    local -i pid=$1
    local monitor_choice=$2
    local led=$3

    while true
    do
        monitor $pid $monitor_choice $led
    done
}

while getopts "p:t:l:" opt; do
    case $opt in
        p)  PID="$OPTARG"
        ;;
        t)  TYPE="$OPTARG"
        ;;
        l)  LED="$OPTARG"
        ;;
    esac
done

monitor_launch $PID $TYPE $LED