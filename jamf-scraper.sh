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
#					      and specifying an output directory (defaults to current user's Desktop). Also
#					      added a Policies report.
#
####################################################################################################
#
# FUTURE FEATURE IDEAS
#
# - Regenerate report from local XML files instead of repull
# - Combined Report View
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
# - Licensed Software Report
# - Mac Applications Report
# - Configuration Profiles Report (Computers and Devices)
# - Extension Attributes Report (Computers and Devices)
# - Packages Report
# - Patch Management Report
# - Inventory Preload Template Generator
#
####################################################################################################

#############
# Variables #
#############

# Base URL for Jamf Pro API endpoint
base_url="https://yourJamfServer.jamfcloud.com/JSSResource"

# Jamf Pro API credentials
api_username="auditorAPI"
api_password="password"

# Output Directory Path (if not specified, will default to current user's Desktop)
outputDirectory=""

# Check to see if outputDirectory is specified and if not default to user's Desktop
if [[ -z "$outputDirectory" ]]; then
	
	# Get the current logged in user
	currentUser=$(who | awk '/console/{print $1}')
	
	# Get the current date in the format YYYY-MM-DD
	current_date=$(date +%Y-%m-%d)
	
	# Set outputDirectory to current user's Desktop
	outputDirectory=/Users/$currentUser/Desktop/jamfScraper-Results_$current_date
fi

# Get the current working directory
script_dir=$(cd "$(dirname "$0")"; pwd)

# Set arguments variable
parameters="$base_url $api_username $api_password $outputDirectory"

#############################
# Generate Folder Structure #
#############################

# Create the XML and Reports folder if it doesn't exist
if [ ! -d "$outputDirectory" ]; then
	mkdir "$outputDirectory"
	mkdir "$outputDirectory/XML"
	mkdir "$outputDirectory/Reports"
fi

############################################################
# Report Selection - Uncomment each report you want to run #
############################################################

#"$script_dir/fragments/computers.sh" $parameters
#"$script_dir/fragments/devices.sh" $parameters
#"$script_dir/fragments/jamf-accounts.sh" $parameters
#"$script_dir/fragments/groups-computer.sh" $parameters
#"$script_dir/fragments/groups-device.sh" $parameters
#"$script_dir/fragments/policies.sh" $parameters
