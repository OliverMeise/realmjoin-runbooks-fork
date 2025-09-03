<#
.SYNOPSIS
Delete a managed device from Intune and delete it from Entra ID. (only iOS/iPadOS)

.DESCRIPTION
Delete a managed device from Intune and delete it from Entra ID. (only iOS/iPadOS)

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
    Write-Output "## Delete device $($targetDevice.displayName) (Object ID $($targetDevice.Id)) in Intune."
    Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices/$($targetDevice.id)" -Method "Delete" -Beta | Out-Null
    
    Write-Output "## Delete $($targetDevice.deviceName) (Object ID $($targetDevice.azureADDeviceId)) in Entra ID"
    Invoke-RjRbRestMethodGraph -Resource "/devices/$($DeviceId)" -Method Delete | Out-Null
}
catch {
    write-error $_
    "## Error Message: $($_.Exception.Message)"
    "## Please see 'All logs' for more details."
    "## Execution stopped."
    throw "Retiring device $($targetDevice.displayName) failed"
}