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

$targetDevice = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices" -OdFilter "azureADDeviceId eq '$DeviceId'" -Beta
## Checking device has been found
if ($null -eq $targetDevice) {
    throw "## Device not found. "
}
"## DeviceId: $($targetDevice.id)"
"## OS: $($targetDevice.operatingSystem)"

try {
    Write-Output "## Retiring device $($targetDevice.displayName) with DeviceId $DeviceId."
    Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices/$($targetDevice.id)/retire" -Method "Post" -Beta | Out-Null
    Write-Output "## Deleting $($targetDevice.deviceName) (Object ID $($targetDevice.id)) from Entra ID"
    Invoke-RjRbRestMethodGraph -Resource "/devices/$($DeviceId)" -Method Delete | Out-Null
}
catch {
    write-error $_
    "## Error Message: $($_.Exception.Message)"
    "## Please see 'All logs' for more details."
    "## Execution stopped."
    throw "Retiring device $($targetDevice.displayName) failed"
}