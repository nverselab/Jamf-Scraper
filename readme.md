# Description

Note: Jamf is depreciating user/password authentication for API. It may be some time before I come back and revise this tool, but feel free to build on it and improve it to fit your needs.

The purpose of this script is to create a custom report of inventory data from Jamf Pro for
reporting, auditing, or archiving records as they exist at runtime.  Inventory object data is pulled
with the Jamf Pro API, formatted, and stored in the XML folder in the directory where the script was run.
Specific values are currated into summary CSV tables for general review in the Reports folder.

This script requires an account in Jamf Pro with Auditor or equivalent permissions. This script
as written will not modify anything in Jamf Pro, but it is always best to use purpose built API accounts
as a precautionary measure.  It is NOT recommended to use any account with Create, Update, or Delete
permissions.

This script will make an API call for each object ID it finds.  In large environments this may result
in hundreds or thousands of calls and will take a long time to complete.  Please be patient.

![Alt text](https://nverselab.com/wp-content/uploads/2023/02/jamfscraper_report_screenshot.png)

# Prerequisits

* Jamf Pro Account with Auditor or equivalent permissions
* IBM Notifier (either in the same folder as the script or path specified in the IBMpath variable)

# Instructions

1. Download the latest version zip file
2. Extract the zip and make all scripts executable. (sudo chmod -R +x ~/Downloads/Jamf-Scraper_version)
3. Run jamf-scraper.sh
4. Enter your Jamf Pro Server URL, API Username, API Password, and desired output path.
5. Select which reports you want to run.
6. Get Coffee
7. Review Reports

### Support My Caffeine Habits
I offer these nuggets of experience freely as a way to give back to the community, but I'm not above accepting a cup of wake-up juice should you wish to share one with me
  
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/A0A3DDISH)
