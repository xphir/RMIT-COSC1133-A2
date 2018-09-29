#!/bin/sh

version=0.1
leds=/sys/class/leds/

main() {
    welcome_message
}

welcome_message(){
    echo "Welcome to Led_Konfigurator!"
    echo "============================"
    echo "Please select an led to configure:"
    echo "Please enter a number (1-9) for the led to configure or quit:"
}

main $@
exit 0
