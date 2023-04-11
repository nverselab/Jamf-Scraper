#!/bin/bash

####################################################################################################
#
# Copyright (c) 2023, NverseLab.com  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the NverseLab.com nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY NverseLab.com "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL NverseLab.com BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################
#
# Description
#
# The purpose of this script is to create a custom report of inventory data from Jamf Pro for
# reporting, auditing, or archiving records as they exist at runtime.  Inventory object data is pulled
# with the Jamf Pro API, formatted, and stored in the XML folder in the directory where the script was run.
# Specific values are currated into summary CSV tables for general review in the Reports folder.
#
# This script requires an account in Jamf Pro with Auditor or equivalent permissions. This script
# as written will not modify anything in Jamf Pro, but it is always best to use purpose built API accounts
# as a precautionary measure.  It is NOT recommended to use any account with Create, Update, or Delete
# permissions.
#
# This scrip will make an API call for each object ID it finds.  In large environments this may result
# in hundreds or thousands of calls and will take a long time to complete.  Please be patient. 
#
####################################################################################################
#
# HISTORY
#
# v0.1.0-a - 02/13/2023 - Initial WIP release to collect Computers, Devices, Jamf Accounts/Groups, 
#                         Computer Groups, and Device Groups. - Jonathan Nelson
# v0.2.0-a - 02/15/2023 - Restructured scripts into fragments to allow for only running enabled reports
#                         and specifying an output directory (defaults to current user's Desktop)
# v0.3.0-a - 02/19/2023 - Implimented prompts for variable input and report selections with IBM Notifier
# v0.4.0-a - 02/20/2023 - Added combined report with colors and formatting for multiple line cells.
#                       - Added group memberships for computers and devices.
# v0.4.1-a - 02/24/2023 - Added Licensed and VPP/App Store Report
# v0.4.2-a - 04/11/2023 - Added Configuration Profiles Reports (Computer and Device)
#						  Added Extension Attributes Reports (Computer and Device)
#						  Added Scripts Report
#						  Customized default folder structure and combined report name and title to reflect the Jamf Pro subdomain.
#
####################################################################################################
#
# FUTURE FEATURE IDEAS
#
# - Server Configuration Summary
#   * Sites
#   * Categories
#   * Buildings
#   * Network Segments
#   * GSX Connection
#   * Healthcare Listeners
#   * Infastructure Managers
#   * LDAP Servers
#   * SMTP Servers
#   * VPP Accounts
#   * Distribution Points
# - Extension Attributes Report (Computers and Devices)
# - Packages Report
# - Patch Management Report
#
####################################################################################################

#############
# Variables #
#############

# Base URL for Jamf Pro API endpoint (Example: https://yourJamfProServer.jamfcloud.com/JSSResource)
base_url=""

# Jamf Pro API credentials
api_username=""
api_password=""

# Output Directory Path (if not specified, will default to current user's Desktop)
outputDirectory=""

# IBM Notifier Path
IBMpath="./IBM\ Notifier.app/Contents/MacOS/IBM\ Notifier"


##############################################################################################################
#                                                                                                            #
#                                     ! DO NOT MODIFY BELOW THIS LINE !                                      #
#                                                                                                            #
##############################################################################################################



###############################################
# Prompt for Jamf API details and output path #
###############################################

# Function to test Jamf Pro API credentials
test_credentials() {
	response=$(curl -sS -u "$api_username:$api_password" "$base_url/buildings" -H "Accept: application/xml" -X GET)
	if [[ $response == *"401 Unauthorized"* ]]; then
		echo "Invalid credentials. Please try again."
		return 1
	else
		echo "The Jamf Pro API credentials are valid or an auth token already exists."
		return 0
	fi
}

# If API variables are empty, prompt for them

if [ -z "$base_url" ]; then
	# Prompt user for Jamf Pro base_url
	IBMbase_url="-type popup -silent -title \"Jamf Scraper\" -accessory_view_type input -accessory_view_payload \"/placeholder https://yourJamfProServer.jamfcloud.com /title Please enter your Jamf Pro Server URL /required\" -main_button_label \"OK\""
	
	IBMcommand="$IBMpath $IBMbase_url"
	
	base_url=$(echo $IBMcommand | sh)
	base_url="$base_url/JSSResource"
fi

if [ -z "$api_username" ]; then
	# Prompt user for API_username
	IBMapi_username="-type popup -silent -title \"Jamf Scraper\" -accessory_view_type input -accessory_view_payload \"/placeholder auditor /title Please enter your Jamf Pro API Username /required\" -main_button_label \"OK\""
	
	IBMcommand="$IBMpath $IBMapi_username"
	
	api_username=$(echo $IBMcommand | sh)
fi

if [ -z "$api_password" ]; then
	# Prompt user for API_password (will not be visible)
	IBMapi_password="-type popup -silent -title \"Jamf Scraper\" -accessory_view_type secureinput -accessory_view_payload \"/placeholder auditorPassword /title Please enter your Jamf Pro API password /required\" -main_button_label \"OK\""
	
	IBMcommand="$IBMpath $IBMapi_password"
	
	api_password=$(echo $IBMcommand | sh)
fi

# Test credentials
test_credentials
while [ $? -ne 0 ]; do
	
	# If API variables are empty, prompt for them
	
	if [ -z "$base_url" ]; then
		# Prompt user for Jamf Pro base_url
		IBMbase_url="-type popup -silent -title \"Jamf Scraper\" -accessory_view_type input -accessory_view_payload \"/placeholder https://yourJamfProServer.jamfcloud.com /title Please enter your Jamf Pro Server URL /required\" -main_button_label \"OK\""
		
		IBMcommand="$IBMpath $IBMbase_url"
		
		base_url=$(echo $IBMcommand | sh)
		base_url="$base_url/JSSResource"
	fi
	
	if [ -z "$api_username" ]; then
		# Prompt user for API_username
		IBMapi_username="-type popup -silent -title \"Jamf Scraper\" -accessory_view_type input -accessory_view_payload \"/placeholder auditor /title Please enter your Jamf Pro API Username /required\" -main_button_label \"OK\""
		
		IBMcommand="$IBMpath $IBMapi_username"
		
		api_username=$(echo $IBMcommand | sh)
	fi
	
	if [ -z "$api_password" ]; then
		# Prompt user for API_password (will not be visible)
		IBMapi_password="-type popup -silent -title \"Jamf Scraper\" -accessory_view_type secureinput -accessory_view_payload \"/placeholder auditorPassword /title Please enter your Jamf Pro API password /required\" -main_button_label \"OK\""
		
		IBMcommand="$IBMpath $IBMapi_password"
		
		api_password=$(echo $IBMcommand | sh)
	fi
	
	# Test credentials again
	test_credentials
done

if [ -z "$outputDirectory" ]; then
# Prompt user for output directory
IBMoutputDirectory="-type popup -silent -title \"Jamf Scraper\" -accessory_view_type input -accessory_view_payload \"/placeholder Leave this field blank to default to your Desktop /title Where would you like to save your reports? \" -main_button_label \"OK\""
	
IBMcommand="$IBMpath $IBMoutputDirectory"
	
outputDirectory=$(echo $IBMcommand | sh)
fi


################################################
# Build IBM Notifier Reports Selection Prompt #
################################################

# Find all .sh files in the fragments subdirectory
sh_files=($(find fragments -maxdepth 1 -type f -name '*.sh' -exec basename {} \;))
sh_files=("${sh_files[@]#fragments/}")
sh_files=("${sh_files[@]%.sh}")
IBMarguments="-type popup -silent -title 'Jamf Scraper Report Selection' -accessory_view_type checklist -accessory_view_payload \"/list"

for file in ${sh_files[@]}; do
	echo "found script: $file"
	IBMarguments=$IBMarguments" $file\n"
done

IBMarguments=$IBMarguments"\""
IBMcommand="$IBMpath $IBMarguments"


# Call IBM Notifier with generated payload
result=$(echo $IBMcommand | sh)

#############################
# Generate Folder Structure #
#############################

# Set instnaceName to the $base_url
instanceName="$base_url"

# Remove http:// or https:// if it exists
instanceName="${instanceName#http://}"
instanceName="${instanceName#https://}"

# Remove all characters after and including the first period
instanceName="${instanceName%%.*}"

# Create the XML and Reports folder if it doesn't exist

# Check to see if outputDirectory is specified and if not default to user's Desktop
if [[ -z "$outputDirectory" ]]; then
	
	# Get the current logged in user
	currentUser=$(who | awk '/console/{print $1}')
	
	# Get the current date in the format YYYY-MM-DD
	current_date=$(date +%Y-%m-%d)
	
	# Set outputDirectory to current user's Desktop
	outputDirectory=/Users/$currentUser/Desktop/$instanceName-Results_$current_date
fi

if [ ! -d "$outputDirectory" ]; then
	mkdir "$outputDirectory"
	mkdir "$outputDirectory/XML"
	mkdir "$outputDirectory/CSV"
	mkdir "$outputDirectory/Reports"
fi

########################
# Run Selected Reports #
########################

# Set arguments variable
parameters="$base_url $api_username $api_password $outputDirectory"

# Parse the user's selections from the response
IFS=' ' read -ra selected_files <<< "$result"
for i in "${selected_files[@]}"; do    
	echo "user selected: ./fragments/${sh_files[$i]}.sh"
	sh ./fragments/${sh_files[$i]}.sh $parameters
done

###################
# Combine Reports #
###################

# Set variables
CSV_FOLDER="$outputDirectory/CSV"
HTML_FILE="$outputDirectory/Reports/$instanceName-Report_$current_date.html"
ROW_COLOR_1="#F4F6F9"
ROW_COLOR_2="#FFFFFF"
HEADER_COLOR="#333333"
CELL_COLOR="#555555"
HEADER_TEXT_COLOR="#FFFFFF"
CELL_TEXT_COLOR="#000000"
TABLE_LABEL_COLOR="#660600"
MENU_BACKGROUND_COLOR="#660600"
MENU_TEXT_COLOR="#FFF"
MENU_HEIGHT="50px"

# Create initial HTML file
echo "<html><head>" > $HTML_FILE
echo "<style>" >> $HTML_FILE
echo "body { padding-top: calc($MENU_HEIGHT * 1.25); }" >> $HTML_FILE
echo "a.menu-link { display: inline-block; color: $MENU_TEXT_COLOR; text-decoration: none; font-weight: bold; padding: 0 10px; line-height: 3; }" >> $HTML_FILE
echo ".menu { position: fixed; top: 0; left: 0; right: 0; height: $MENU_HEIGHT; background-color: $MENU_BACKGROUND_COLOR; z-index: 9999; display: flex; flex-wrap: nowrap; overflow-x: auto; -webkit-overflow-scrolling: touch; white-space: nowrap;}" >> $HTML_FILE
echo "table {border-collapse: collapse; width: 100%;}" >> $HTML_FILE
echo "th, td {text-align: left; padding: 8px;}" >> $HTML_FILE
echo "th {background-color: $HEADER_COLOR; color: $HEADER_TEXT_COLOR; position: sticky; top: 50;}" >> $HTML_FILE
echo "tr:nth-child(even) {background-color: $ROW_COLOR_2; color: $CELL_TEXT_COLOR;}" >> $HTML_FILE
echo "tr:nth-child(odd) {background-color: $ROW_COLOR_1; color: $CELL_TEXT_COLOR;}" >> $HTML_FILE
echo "</style>" >> $HTML_FILE
echo "</head><body style='color:$CELL_TEXT_COLOR'>" >> $HTML_FILE

# Add menu to HTML file
echo "<div class='menu'>" >> $HTML_FILE
echo "<a class='menu-link'>Jump to: </a>" >> $HTML_FILE
for file in $CSV_FOLDER/*.csv
do
	# Get table label from filename
	TABLE_LABEL=$(basename "$file" .csv)
	
	# Count number of rows in CSV file
	NUM_ROWS=$(($(wc -l < "$file")-1))
	
	# Append row count to table label
	TABLE_LABEL="$NUM_ROWS $TABLE_LABEL"
	
	# Remove the datestamp from the link text
	TABLE_LINKTEXT=`echo "${TABLE_LABEL}" | sed 's/...........$//'` 
	echo "<a class='menu-link' href='#$TABLE_LABEL'>$TABLE_LINKTEXT</a>" >> $HTML_FILE
done

echo "</div>" >> $HTML_FILE

# Add Title to HTML File
echo "<h1 style='color:$CELL_TEXT_COLOR'>$instanceName - Combined Report</h1>" >> $HTML_FILE

# Loop through CSV files
for file in $CSV_FOLDER/*.csv
do
	# Get table label from filename
	TABLE_LABEL=$(basename "$file" .csv)
	
	# Count number of rows in CSV file
	NUM_ROWS=$(($(wc -l < "$file")-1))
	
	# Append row count to table label
	TABLE_LABEL="$NUM_ROWS $TABLE_LABEL"
	
	
	# Add table header to HTML file
	echo "<h2 style='color:$TABLE_LABEL_COLOR' id='$TABLE_LABEL'>$TABLE_LABEL</h2>" >> $HTML_FILE
	echo "<table>" >> $HTML_FILE
	echo "<thead><tr>" >> $HTML_FILE
	
	# Loop through column headers and add to table
	HEADERS=$(head -n 1 "$file")
	IFS=',' read -r -a HEADER_ARRAY <<< "$HEADERS"
	for header in "${HEADER_ARRAY[@]}"
	do
		echo "<th>$header</th>" >> $HTML_FILE
	done
	
	# Add table body to HTML file
	echo "</tr></thead>" >> $HTML_FILE
	echo "<tbody>" >> $HTML_FILE
	
	# Loop through CSV file and add rows to table
	NUM_ROWS=$(wc -l < "$file")
	NUM_ROWS=$((NUM_ROWS-1)) # Subtract 1 for the header row
	while read line
	do
		echo "<tr style='color:$CELL_TEXT_COLOR; background-color:$ROW_COLOR_1;'><td>${line//,/</td><td>}</td></tr>" | sed 's/;/<br>/g' >> $HTML_FILE
		ROW_COLOR_TEMP=$ROW_COLOR_1
		ROW_COLOR_1=$ROW_COLOR_2
		ROW_COLOR_2=$ROW_COLOR_TEMP
	done < <(tail -n +2 "$file")
	
	# Close the table
	echo "</tbody></table>" >> $HTML_FILE
done


#####################
# Completion Prompt #
#####################

# Let the user know everything is finished and open the reports folder
IBMcomplete="-type popup -title \"Jamf Scrape Complete\" -subtitle \"Click OK to open your reports directory.\" -main_button_label \"OK\""
IBMcommand="$IBMpath $IBMcomplete"
complete=$(echo $IBMcommand | sh)
open $outputDirectory/Reports


exit 0