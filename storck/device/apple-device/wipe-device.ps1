<#
.SYNOPSIS
Wipes an iOS device.

.DESCRIPTION
This script is used to perform a wipe operation on an Apple iOS device, removing all data and restoring it to factory settings.

.NOTES
PERMISSIONS
DeviceManagementManagedDevices.ReadWrite.All
Device.Read.All
ROLES
Cloud device administrator

.INPUTS
RunbookCustomization: {
    "Parameters": {
        "DeviceId": {
            "Hide": true
        },
        "CallerName": {
            "Hide": true
        }
    }
}
#>

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.8.3" }

param (
    [Parameter(Mandatory = $true)]
    [string] $DeviceId,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Write-RjRbLog -Message "Caller: '$CallerName'" -Verbose

$Version = "1.0.0"
Write-RjRbLog -Message "Version: $Version" -Verbose

Connect-RjRbGraph

# "Searching DeviceId $DeviceID."
$targetDevice = Invoke-RjRbRestMethodGraph -Resource "/devices" -OdFilter "deviceId eq '$DeviceId'" -ErrorAction SilentlyContinue
if (-not $targetDevice) {
    throw ("DeviceId $DeviceId not found in Entra ID.")
}

"## Deleting $($targetDevice.displayName) (Object ID $($targetDevice.id)) from Entra ID"
try {
    Invoke-RjRbRestMethodGraph -Resource "/devices/$($targetDevice.id)" -Method Delete | Out-Null
}
catch {
    "## Error Message: $($_.Exception.Message)"
    "## Please see 'All logs' for more details."
    "## Execution stopped." 
    throw "Deleting Object ID $($targetDevice.id) from Entra ID failed!"
    
}



$mgdDevice = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices" -OdFilter "azureADDeviceId eq '$DeviceId'" -ErrorAction SilentlyContinue
if ($mgdDevice) {
    "## Wiping DeviceId $DeviceID (Intune ID: $($mgdDevice.id))"
    $body = @{
        "keepEnrollmentData" = "false"
        "keepUserData"       = "false"
    }
    try {
        Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices/$($mgdDevice.id)/wipe" -Method Post -Body $body -Beta | Out-Null
    }
    catch {
        "## Error Message: $($_.Exception.Message)"
        "## Please see 'All logs' for more details."
        "## Execution stopped."     
        throw "Wiping DeviceID $DeviceID (Intune ID: $($mgdDevice.id)) failed!"
    }
}
else {
    "## Device not found in Intune. Skipping."
}