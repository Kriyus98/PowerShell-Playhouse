This PowerShell script is created to cleanup files on Windows OS.
It incorporates a JSON file containing configurable file paths to cleanup.
Adding additional paths to the JSON will be picked up by the PowerShell script on the next execution.
It will loop through all files in each file path and delete files older than the "daysToDelete" value in the JSON.
It will also display the number and size of files deleted from each path, before showing the total files and size deleted.
Finally it will clear the recycling bin for each user.