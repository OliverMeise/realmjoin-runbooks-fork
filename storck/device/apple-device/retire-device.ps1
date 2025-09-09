<#
.SYNOPSIS
Retire a managed device from Intune (removes management and wipes company data) and delete it from Entra ID. (only iOS/iPadOS)

.DESCRIPTION
This script retires a managed device in Intune using Microsoft Graph. It verifies the device exists and then sends a retire command.

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

param(
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

## Checking device has been found
$targetManagedDevice = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices" -OdFilter "azureADDeviceId eq '$DeviceId'" -Beta
if ($null -eq $targetManagedDevice) {
    throw "## Device not found. "
}
"## DeviceId: $($targetManagedDevice.id)"
"## OS: $($targetManagedDevice.operatingSystem)"

# "Searching DeviceId $DeviceID."
$targetDevice = Invoke-RjRbRestMethodGraph -Resource "/devices" -OdFilter "deviceId eq '$DeviceId'" -ErrorAction SilentlyContinue
if (-not $targetDevice) {
    throw ("DeviceId $DeviceId not found in Entra ID.")
}

"## Entra ID ObjectId: $($targetDevice.id)"

try {
    # Retire device in Intune
    Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices/$($targetManagedDevice.id)/retire" -Method "Post" -Beta | Out-Null
    Write-Output "## Retiring device $($targetManagedDevice.displayName) with DeviceId $DeviceId."
    # Delete device in Entra ID
    Invoke-RjRbRestMethodGraph -Resource "/devices/$($targetDevice.id)" -Method Delete | Out-Null
    Write-Output "## Deleting $($targetManagedDevice.deviceName) (Object ID $($targetDevice.id)) from Entra ID"
}
catch {
    write-error $_
    "## Error Message: $($_.Exception.Message)"
    "## Please see 'All logs' for more details."
    "## Execution stopped."
    throw "Retiring device $($targetManagedDevice.displayName) failed"
}
