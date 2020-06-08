#!/bin/bash   
## Version 0.1 
## Coded by James Mackay

WORKINGDIR="/home/s1mpleman/Scripts/"
PAUSE="2"

import -window "$(xdotool getwindowfocus -f)" -silent -pause ${PAUSE} "${WORKINGDIR}screenshot.png"

import -window "$(xdotool getwindowfocus -f)" -crop 1583x792+285+32 "${WORKINGDIR}screenshot.png"

OUTPUT=$(base64 "${WORKINGDIR}screenshot.png")

echo " " > "${WORKINGDIR}base64.txt"

echo " thumbnail begin 220x124 24320" >> "${WORKINGDIR}base64.txt"

echo "${OUTPUT}" >> "${WORKINGDIR}base64.txt"

echo " thumbnail end" >> "${WORKINGDIR}base64.txt"

sed -i 's/^/;/' "${WORKINGDIR}base64.txt"

cat "${WORKINGDIR}base64.txt" "$1" > "${WORKINGDIR}newFile.gcode"; mv "${WORKINGDIR}newFile.gcode" "$1"

