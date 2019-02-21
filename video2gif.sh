#!/usr/bin/sh
#################################################################
# video2gif Converter
# Copyright 2019  Alexandre Díaz Cuadrado - <dev@redneboa.es>
# License GPL-3.0 or later (http://www.gnu.org/licenses/gpl).
#
#
# USAGE: video2gif <FILE> [QUALITY]
# PARAMETERS
# - [QUALITY]
#     · low: 5fps + %3 fuzz + 128 Colors
#     · medium (default): 5fps + %3 fuzz
#     · high: 15 fps + %1 fuzz
#     · ultra: 25 fps
# - <FILE> Input file to convert
#################################################################

# Input Params
QUALITY=$1
FILE=$2

if [ -z $FILE ] || [ -z $QUALITY ]; then
  echo "Invalid Parameters!  Aborting."
  echo -e "\nUSAGE: $0 <QUALITY> <FILE>"
  exit 1
fi
if ! [ -f $FILE ]; then
  echo "Input file doesn't exists.  Aborting."
  exit 1
fi


# Util Methods
function join { local IFS="$1"; shift; echo "$*"; }
function check_dep { command -v $1 >/dev/null 2>&1 || { echo "$1 it's required but it's not installed.  Aborting."; exit 1; } }


# Check System Tools
check_dep ffmpeg
check_dep convert
check_dep gifsicle


# Script Variables
NCOLORS="255"
THREADS=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`

IFS='.' read -ra FILE_ARR <<< "$FILE"
ORG_FORMAT=${FILE_ARR[-1]}
unset FILE_ARR[-1]
FILE_NO_EXT=$(join . ${FILE_ARR[@]})
OUT="$FILE_NO_EXT.gif"

if [ "$QUALITY" = "low" ]; then
  FPS="5"
  FUZZ="3%"
  NCOLORS="128"
elif [ "$QUALITY" = "medium" ]; then
  FPS="5"
  FUZZ="3%"
elif [ "$QUALITY" = "high" ]; then
  FPS="15"
  FUZZ="1%"
elif [ "$QUALITY" = "ultra" ]; then
  FPS="25"
else
  echo "Invalid Quality Option.  Aborting."
  echo -e "\nAvailable: low, medium, high, ultra"
  exit 1
fi


# Run Magic
ffmpeg -y -i $FILE -vf "fps=$FPS,palettegen=stats_mode=diff" "$OUT.png"
ffmpeg -y -i $FILE -i "$OUT.png" -filter_complex "fps=$FPS,paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" $OUT
rm "$OUT.png"
if ! [ -z $FUZZ ]; then
  convert $OUT -fuzz $FUZZ -layers Optimize $OUT
fi
gifsicle -w -O3 --colors $NCOLORS -o $OUT -j$THREADS $OUT
