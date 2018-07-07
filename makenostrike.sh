#!/bin/bash

# This script creates a list of hosts that should be excluded from subsequent operations,
# generating the output into file exclude.hosts
# REQUIRES: nmap

# Establish a path to the temp files and working diretory for output
TMPPATH="/root/temp/"
WRKPATH="/root/working/"

# Ensure that the above directories exist
if [ ! -d $TMPPATH ]; then
	mkdir $TMPPATH
fi

if [ ! -d $WRKPATH ]; then
	mkdir $WRKPATH
fi

echo Enter a comma seperated list of hosts that should be placed
echo on the no-strike list. Output will be the file "$WRKPATH"exclude.hosts
printf "\n"
echo Entries may include CIDR notation, or may include dashes, e.g.
echo 192.168.2.12-36,192.168.4.6,192.168,192.168.6.0/24
printf "\n"
read -p "> " EXCLUDE

# Copy user input string into a temp file for processing
echo $EXCLUDE > "$TMPPATH"exclude.tmp
# Replace any commas with new lines so that you have a list, output to a temp file
tr ',' '\n' < "$TMPPATH"exclude.tmp > "$TMPPATH"excludelined.tmp
# Write any single IP lines to the final output file, exluding cidr or dashed ranges
grep -v "-" "$TMPPATH"excludelined.tmp | grep -v "/" > "$TMPPATH"unsorted.tmp

# If the original input string did have a dashed range, move those lines into a temp file
# and then move those IP ranges into a variable to enable expanding into a list with nmap

	if [[ $EXCLUDE = *"-"* ]]; then
		grep "-" "$TMPPATH"excludelined.tmp > "$TMPPATH"dashedips.tmp
		DASHED=$(<"$TMPPATH"dashedips.tmp)
		nmap -n -sL $DASHED | grep "Nmap scan" | cut -d " " -f5 >> "$TMPPATH"unsorted.tmp
		rm "$TMPPATH"dashedips.tmp
	fi

# If the original input string had CIDR ranges, move those lines into a temp file
# and then move those IP ranges into a variable to enable expanding into a list with nmap

	if [[ $EXCLUDE = *"/"* ]]; then
		grep "/" "$TMPPATH"excludelined.tmp > "$TMPPATH"cidrips.tmp
		CIDR=$(<"$TMPPATH"cidrips.tmp)
		nmap -n -sL $CIDR | grep "Nmap scan" | cut -d " " -f5 >> "$TMPPATH"unsorted.tmp
		rm "$TMPPATH"cidrips.tmp
	fi

# sort the temp file into the final output, really just for ease of manual verification
# if trying to confirm a particular IP address is on the list
sort "$TMPPATH"unsorted.tmp > "$WRKPATH"exclude.hosts

# cleanup remaining temp files
rm "$TMPPATH"excludelined.tmp "$TMPPATH"exclude.tmp "$TMPPATH"unsorted.tmp
