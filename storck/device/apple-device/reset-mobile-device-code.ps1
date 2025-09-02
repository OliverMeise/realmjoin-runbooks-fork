<#
.SYNOPSIS
Reset a mobile device code.

.DESCRIPTION
Reset a mobile device code.

.NOTES
Permissions needed:
- DeviceManagementManagedDevices.Read.All,
- DeviceManagementManagedDevices.PrivilegedOperations.All

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
    [String] $DeviceId,
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
    ## Highly unlikely
    throw "## Device not found."
}

"## DeviceId: $($targetDevice.id)"
"## LostMode: $($targetDevice.lostModeState)"
"## OS: $($targetDevice.operatingSystem)"

if ($targetDevice.operatingSystem -ne "iOS") {
    "## Can not reset device code for non-iOS devices."
    throw ("OS not supported")
}

## Checking the device's Owner Type. Reset Passcode works only with corporate-owned deivces.
if ($targetDevice.managedDeviceOwnerType -eq "personal" -or $targetDevice.managedDeviceOwnerType -eq "unknown" ) {
    throw "## Device '$($targetDevice.deviceName)' is not corporate-owned. Cannot reset device code. `n## Aborting..."
}

## Post the resetPasscode action and if possible it will execute, otherwise will result in an exception
try {
    Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices('$($targetDevice.id)')/resetPasscode" -Method Post -Beta

    "## Device Passcode has been reset."
}
catch {
    write-error $_
    "## Error Message: $($_.Exception.Message)"
    "## Please see 'All logs' for more details."
    "## Execution stopped."
    throw "Reset device code for device $($targetDevice.displayName) failed"
}
