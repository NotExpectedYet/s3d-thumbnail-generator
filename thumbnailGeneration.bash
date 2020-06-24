#!/bin/bash   
## Version 0.2 
## Coded by James Mackay
## Extra code by Elminster


#########################
# Variables & Constants #
#########################

# Set up Common Basic Constants
WORKINGDIR="/tmp/"
DEFAULT_THUMBMETHOD="SNAP" #Methods SNAP, EXTERNAL, SCAD, GCODE, FILE
STLDIR="$HOME/Work/3dprinting/Models"
PNGDIR=$STLDIR	#if using externally generated pngs
DEBUG_LOG="TRUE"  # debug ON if set to TRUE [TRUE|FALSE]
DEBUG_LOG_FILE="/tmp/debug.txt"

# Set up Common Basic Parameters
GCODEFILE="$1"
THUMBPARAM="$2"
THUMBFILE="$3"
VERSION=0.2
IAM=`basename $0`

# Set up Parameters for snapshot
PAUSE="2"
CROPSIZE="600x400+600+140"  # crop a snapshot png, x size, y size, x offset, y offset

# Set up Parameters for OpenSCAD - Linux
case "$OSTYPE" in
    darwin*)
        #place holder for mac
        #GETWINDOWID="$(xdotool getwindowfocus -f)"  #Get ID of S3D window so we can snapshot it
        SCADBIN="/usr/local/bin/openscad" #Symlink, Assumes installed via Homebrew
        #SCADLIB="/usr/lib/x86_64-linux-gnu" #openscad cant find libraries when run inside S3D
        ;;
    win32) #guess not sure
        echo "not implemented" 
        ;;
    *)  #assume some form of Linux
        GETWINDOWID="$(xdotool getwindowfocus -f)"  #Get ID of S3D window so we can snapshot it
        SCADBIN="/usr/bin/openscad" #Full path of SCAD binary
        SCADLIB="/usr/lib/x86_64-linux-gnu" #openscad cant find libraries when run inside S3D
        ;;
esac


#################
# Sanitu checks #
#################
# Check Parameter is not missing, this is the S3D [output_filepath] parameter
if [ ! "$GCODEFILE" == "" ] 
	then BASEFILE=$(basename "$GCODEFILE" | cut -d. -f1) 
else 
	echo "Missing Parameter: GCODE filename" ; exit 1 
fi

# Check if parameter 2 is null, or set to something
if [ "$THUMBPARAM" == "" ] 
	then THUMBMETHOD=$DEFAULT_THUMBMETHOD #If null then set to the default method
else 
	THUMBMETHOD=$THUMBPARAM 
fi


#######################
# Define functions ####
#######################
function fn_findfile    # Find a file in a given directory
{
	# Param 1 = Filename to find without extension
	# Param 2 = Filename extension
	# Param 3 = Directory structure to search
	# Param 4 = Case Sensitive [CASE | NOCASE]
	fn_logdebug "Finding ...."
	fn_logdebug "$3 ... $1 | $2 | $4" 
	
	if [ $4 == "NOCASE" ]
	then
		fn_logdebug "Found ...." 
		fn_logdebug "$(find "$3" -iname "$1"."$2" -print -quit)" 
		echo $(find "$3" -iname "$1"."$2" -print -quit)
	else
		fn_logdebug "Found ...." 
		fn_logdebug "$(find "$3" -name "$1"."$2" -print -quit)" 
		echo $(find "$3" -name "$1"."$2" -print -quit)
	fi
}

function fn_snapshot    # function to take screenshot
{  
	# Param 1 = xwindow id
	fn_logdebug "Snapping ...." 
	# Note this may fail if the user naviagates away from S3D to quickly
	import -window "$1" -silent -pause ${PAUSE} "${WORKINGDIR}screenshot.png"
	import -window "$1" -crop ${CROPSIZE} "${WORKINGDIR}screenshot.png"
}

function fn_openscad    # function to take use openscad to create png from stl file
{
	# Param 1 = stl file to convert
	fn_logdebug "Using SCAD method ...." 
	STLFILE="$1"
    if [ "$STLFILE" ]
    then
	    echo import\(\"$STLFILE\"\)\; >"${WORKINGDIR}/${BASEFILE}".tmp
	    LD_LIBRARY_PATH=$SCADLIB
	    $SCADBIN -o "${WORKINGDIR}screenshot.png" --imgsize=220,124 "${WORKINGDIR}/${BASEFILE}".tmp
    else
        fn_logdebug "Cannot find STL file, fallback to snapshot ...." 
		fn_snapshot "${GETWINDOWID}" # No file was specified fallback to snapshot
    fi
}

function fn_show_usage    # Display command line usage message and exit
{
    # Param 1 = exit level
	echo
	echo "\t${IAM} version ${VERSION}."
	echo "\tSee documentation on github."
	echo
	exit $1
}

function fn_logdebug
{
     # Param 1 = Message to write to log file
    [ $DEBUG_LOG = "TRUE" ] && echo "$1" >> $DEBUG_LOG_FILE 
}

# Initialize Debug Logfile
[ $DEBUG_LOG = "TRUE" ] && echo "" > $DEBUG_LOG_FILE
[ $DEBUG_LOG = "TRUE" ] && exec 2>>$DEBUG_LOG_FILE   # ReDirect STDERR to the debugfile
fn_logdebug "$GCODEFILE"
fn_logdebug "$BASEFILE"


#######################
# Main Program ########
#######################

# Select Option - Main Controller CASE statement
case "$THUMBMETHOD" in
    SNAP)
		# Take a snapshot of the S3D model window
        fn_snapshot "${GETWINDOWID}"
        ;;
    SCAD)
		# Use openSCAD to generate PNG from STL. Try to find filebased on GCODE name
        GETFILENAME="$(fn_findfile """$BASEFILE""" stl """$STLDIR""" CASE)" 
		# Failed to find exact file match with .stl postfix, try same search again case insensitive
		: ${GETFILENAME:=$(fn_findfile """$BASEFILE""" stl """$STLDIR""" NOCASE)}
		fn_logdebug "Filename being sent to openscad $GETFILENAME"
		fn_openscad "$GETFILENAME"
        ;;      
    EXTERNAL)
		# Look for png file with same name as gcode file in specified png directory
        fn_logdebug "Look for EXTERNAL" 
	    PNGFILE="$(fn_findfile """$BASEFILE""" png """$PNGDIR""")"
	    cp "${PNGFILE}" "${WORKINGDIR}screenshot.png"
        ;;
    FILE)
		# Looks for user specified file
        if [ ! "${THUMBFILE}" ] ; then 
		    fn_logdebug "FILE specified but filename parameter is null, fallback to snapshot ...." 
		    fn_snapshot "${GETWINDOWID}" # No file was specified fallback to snapshot
	    elif [ ! -f "${THUMBFILE}" ] ; then 
		    fn_logdebug "FILE in parameter does not exist/readable, fallback to snapshot ...." 
		    fn_snapshot "${GETWINDOWID}" # No file was specified fallback to snapshot
	    else
		    fn_logdebug "copying FILE" 
		    FILEEXT=$(basename "$THUMBFILE" | cut -d. -f2) 
		    if [ "$FILEEXT" == "stl" ] ; then
		        fn_openscad "$THUMBFILE"
		    elif [ "$FILEEXT" == "png" ] ; then
		        cp "${THUMBFILE}" "${WORKINGDIR}screenshot.png"
		    else
		        fn_logdebug "Not sure what to do with this extension, giving up ...." 
		        exit 1
		    fi
	    fi
        ;;
    GCODE)
        echo "Not Implemented"
        fn_logdebug "Not Implemented ...." 
        ;;
    *)
        echo "Invalid Option"
	    fn_logdebug "Invalid Option ...." 
        fn_show_usage 1
esac

fn_logdebug "Converting Imagine to Ascii ...." 

# Something went wrong, screenshot is missing
if [ ! -f "${WORKINGDIR}screenshot.png" ]
then
	fn_logdebug "screenshot is missing, aborting ...." 
	exit 1
fi

# We now have the screenshot, now convert to ascii and merge it into the gcode that s3D pumped out
OUTPUT=$(base64 "${WORKINGDIR}screenshot.png")

echo " " > "${WORKINGDIR}base64.txt"    								# zero file
echo " thumbnail begin 220x124 24320" >> "${WORKINGDIR}base64.txt"   	#header
echo "${OUTPUT}" >> "${WORKINGDIR}base64.txt"  							#dump ascii version of screenshot into file
echo " thumbnail end" >> "${WORKINGDIR}base64.txt"  					#footer

# Empty quotes required for BSD/Mac sed compatability
sed -i '' 's/^/;/' "${WORKINGDIR}base64.txt"								#Add gcode comment to ascii encoded lines

fn_logdebug "Merging thumbnail into gcode ...." 

# Merge ascii screen shot into gcode and replace original gcode file that S3D pumped out
cat "${WORKINGDIR}base64.txt" "$GCODEFILE" > "${WORKINGDIR}newFile.gcode"; mv "${WORKINGDIR}newFile.gcode" "$GCODEFILE"

# In debug mode show that screebshot was processed by renaming
[ $DEBUG_LOG ] && mv ${WORKINGDIR}screenshot.png ${WORKINGDIR}screenshot_processed.png


#######################
# The End #############
#######################