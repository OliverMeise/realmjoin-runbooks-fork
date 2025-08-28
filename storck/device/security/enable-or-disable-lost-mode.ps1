<#
.SYNOPSIS
Enable oder disable the lost mode.

.DESCRIPTION
Enable oder disable the lost mode.

  .INPUTS
  RunbookCustomization: {
        "Parameters": {
            "Enable": {
                "DisplayName": "Disable or enable lost mode",
                "SelectSimple": {
                    "Disable lost mode": false,
                    "Enable lost mode": true
                }
            },
            "DeviceId": {
                "Hide": true
            },
            "CallerName": {
                "Hide": true
            },
            "Enable": {
                "DisplayName": "Disable or Enable Device"
            }
        }
    }
#>

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.8.4" }

param(
    [Parameter(Mandatory = $true)]
    [string] $DeviceId,
    [bool] $Enable = $false,
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
    throw ("DeviceId $DeviceId not found.")
}

if ($targetDevice.operatingSystem -notin "IPad","IPhone") {
    "## Can not en-/disable lost mode for non-iOS devices currently."
    throw ("OS not supported")
}

####
# POST /deviceManagement/managedDevices/$($targetDevice.id)/enableLostMode
# POST /deviceManagement/managedDevices/{managedDeviceId}/disableLostMode
####


$body = @{
    "message" = "Message value"
    "phoneNumber" = "Phone Number value"
    "footer" = "Footer value"
}

if ($targetDevice.lostModeState -eq "Enabled") {
    if ($Enable) {
        "## Device $($targetDevice.displayName) with DeviceId $DeviceId is already in lost mode."
    }
    else {
        "## Disabling lost mode for device $($targetDevice.displayName) with DeviceId $DeviceId."
        try {
            Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices/$($targetDevice.id)/disableLostMode" -Method "Post" -Beta | Out-Null
        }
        catch {
            write-error $_
            throw "Disabling lost mode of device $($targetDevice.displayName) failed"
        }
    }
}
else {
    if ($Enable) {
        "## Enabling lost mode for device $($targetDevice.displayName) with DeviceId $DeviceId."
        try {
            Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices/$($targetDevice.id)/enableLostMode" -Method "Post" -body $body| Out-Null
        }
        catch {
            write-error $_
            throw "Enabling lost mode of device $($targetDevice.displayName) failed"
        }
    }
    else {
        "## Device $($targetDevice.displayName) with DeviceId $DeviceId is already in lost mode."
    }
}