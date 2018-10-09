#!/bin/bash
LEDS_FOLDER=/sys/class/leds/

led_triggers() {
    local led=$1
    cat "${LEDS_FOLDER}${led}/trigger"
}

led_triggers led0