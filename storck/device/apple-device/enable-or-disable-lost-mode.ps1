<#
.SYNOPSIS
Enable the lost mode. PLEASE NOTE: Only activation is currently possible. For deactivation, please contact Frederik or Luca.

.DESCRIPTION
Enable oder disable the lost mode (only iOS/iPadOS).

.INPUTS
RunbookCustomization: {
        "Parameters": {
            },
            "DeviceId": {
                "Hide": true
            },
            "CallerName": {
                "Hide": true
            }
        }
    }
#>
#region RunbookCustomization wenn lostmodestate funktioniert

<#
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
}

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.8.3" }

param(
    [Parameter(Mandatory = $true)]
    [string] $DeviceId,
    [bool] $Enable = $true,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)
#>
#endregion
                    

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.8.3" }

param(
    [Parameter(Mandatory = $true)]
    [string] $DeviceId,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName,
    [ValidateScript( { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; Use-RJInterface -Type Textarea } )]
    [string] $Message = "Bitte geben Sie das Gerät bei der Polizei oder im Fundbüro ab.",
    [ValidateScript( { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; Use-RJInterface -Type Textarea } )]
    [string] $PhoneNumber = "+495201128558",
    [ValidateScript( { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; Use-RJInterface -Type Textarea } )]
    [string] $Footer = "August Storck KG, Paulinenweg 12, 33790 Halle (Westf.), Germany"
)

Write-RjRbLog -Message "Caller: '$CallerName'" -Verbose

$Version = "1.0.0"
Write-RjRbLog -Message "Version: $Version" -Verbose

Connect-RjRbGraph

$targetDevice = Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices" -OdFilter "azureADDeviceId eq '$DeviceId'" -Beta
## Checking device has been found
if ($null -eq $targetDevice) {
    ## Highly unlikely
    throw "## Device not found. "
}
"## DeviceId: $($targetDevice.id)"
"## LostMode: $($targetDevice.lostModeState)"
"## OS: $($targetDevice.operatingSystem)"

if ($targetDevice.operatingSystem -ne "iOS") {
    "## Can not en-/disable lost mode for non-iOS devices currently."
    throw ("OS not supported")
}

####
# POST /deviceManagement/managedDevices/$($targetDevice.id)/enableLostMode
# POST /deviceManagement/managedDevices/{managedDeviceId}/disableLostMode
####

$body = @{
    "message" = $Message #"Bitte geben Sie das Gerät bei der Polizei oder im Fundbüro ab. August Storck KG, Paulinenweg 12, 33790 Halle (Westf.), Germany"
    "phoneNumber" = $PhoneNumber #"+495201128558"
    "footer" = $Footer #"Footer value"
}
"## Enabling lost mode for device $($targetDevice.displayName) with DeviceId $DeviceId."
        try {
            Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices/$($targetDevice.id)/enableLostMode" -Method "Post" -Beta -body $body| Out-Null
        }
        catch {
            write-error $_
            throw "Enabling lost mode of device $($targetDevice.displayName) failed"
        }

#region RunbookCustomization wenn lostmodestate funktioniert
<#
if ($targetDevice.lostModeState -eq "Enabled") {
    if ($Enable) {
        "## Device $($targetDevice.displayName) with DeviceId $DeviceId is already in lost mode."
    }
    else {
        "## Disabling lost mode for device $($targetDevice.displayName) with DeviceId $DeviceId."
        try {
            Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices/$($targetDevice.id)/disableLostMode" -Method "Post" | Out-Null
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
            Invoke-RjRbRestMethodGraph -Resource "/deviceManagement/managedDevices/$($targetDevice.id)/enableLostMode" -Method "Post" -Beta -body $body| Out-Null
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
#>
#endregion