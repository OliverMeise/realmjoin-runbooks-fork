<#
  .SYNOPSIS
  Remove/Outphase multiple devices

  .DESCRIPTION
  Remove/Outphase multiple devices. You can choose if you want to wipe the device and/or delete it from Intune an AutoPilot.

  .NOTES
  PERMISSIONS
   DeviceManagementManagedDevices.PrivilegedOperations.All (Wipe,Retire / seems to allow us to delete from AzureAD)
   DeviceManagementManagedDevices.ReadWrite.All (Delete Inunte Device)
   DeviceManagementServiceConfig.ReadWrite.All (Delete Autopilot enrollment)
   Device.Read.All
   Device.ReadWrite.All (Required for extensionAttribute modifications)
   Directory.ReadWrite.All (Alternative permission for device modifications)
  ROLES
   Cloud device administrator

  .INPUTS
  RunbookCustomization: {
    "Parameters": {
        "purpose": {
            "DisplayName": "Select the purpose of the device",
            "DefaultValue": "OfficeDevice",
            "Select": {
                "Options": [
                    {
                        "Display": "Office device",
                        "Value": "OfficeStandard",
                        "Customization": {
                            "Hide": [
                                "purposeType"
                            ]
                        }
                    },
                    {
                        "Display": "Special device",
                        "Value": "SpecialDevice",
                        "Customization": {
                            "Hide": [
                                "username"
                            ]
                        }
                    }
                ]
            }
        },
        "location": {
            "DisplayName": "Select the location of the device",
            "SelectSimple": {
                "Almaty (ALM)": "ALM",
                "Antwerp (ANT)": "ANT",
                "Barcelona (BAR)": "BAR",
                "Basingstoke (BAS)": "BAS",
                "Berlin (BER)": "BER",
                "Berlin Flohrstrasse (FLO)": "FLO",
                "Bratislava (BRA)": "BRA",
                "Budapest (BUD)": "BUD",
                "Chicago (CHI)": "CHI",
                "Dubai (DUB)": "DUB",
                "Halle (HAL)": "HAL",
                "Hoevelaken (HOE)": "HOE",
                "Ljubljana (LJU)": "LJU",
                "Malmö (BRO)": "BRO",
                "Milano (MIL)": "MIL",
                "Mississauga (MIS)": "MIS",
                "Moscow (MOS)": "MOS",
                "Ohrdruf (OHR)": "OHR",
                "Paris (PAR)": "PAR",
                "Prague (PRA)": "PRA",
                "Quito (QUI)": "QUI",
                "Salzburg (SAL)": "SAL",
                "Santiago (SAN)": "SAN",
                "Santo Domingo (SDO)": "SDO",
                "Singapore (SIN)": "SIN",
                "Taunusstein (TAU)": "TAU",
                "Warszaw (WAR)": "WAR",
                "Zagreb (ZAG)": "ZAG",
                "Zürich (ZUR)": "ZUR"
            },
            "Hide":false
        },
        "purposeType": {
            "Displayname": "Select the purpose type",
            "SelectSimple": {
                "ConferenceRooms": "ConferenceRooms",
                "Laboratory": "Laboratory",
                "Logistics": "Logistics",
                "PlantSecurity": "PlantSecurity",
                "SAP PM": "SAP PM",
                "ServiceTerminals": "ServiceTerminals"
            },
            "Hide":false
        },
        "device": {
            "DisplayName": "Select device by serialnumber",
            "Hide":false
        },
        "CallerName": {
            "Hide": true
        }
    }
}
#>

#Requires -Modules @{ModuleName = "RealmJoin.RunbookHelper"; ModuleVersion = "0.8.3" }

param (
    # The purpose of the device, e.g. OfficeDevice, SpecialDevice
    [Parameter(Mandatory)]
    [string] $purpose,
    # The location of the device, e.g. Berlin, Frankfurt, Hamburg, Munich, Halle (Westfl.)
    [Parameter(Mandatory)]
    [string] $location,
    # The device to assign, e.g. serialnumber
    [ValidateScript( { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; Use-RJInterface -Type Graph -Entity Device} )]
    [Parameter(Mandatory)]
    [string] $device,
    # The user to assign the device to, e.g. username
    #[ValidateScript( { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; Use-RJInterface -Type Graph -Entity User} )]
    #[string] $username,
    # The purpose type of the device, e.g. PM, Laboratory, Logistics
    [string] $purposeType,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory)]
    [string] $CallerName
)


Write-RjRbLog -Message "Caller: '$CallerName'" -Verbose

$Version = "1.0.0"
Write-RjRbLog -Message "Version: $Version" -Verbose

# Validate that purposeType is not empty when purpose is SpecialDevice
if ($purpose -eq "SpecialDevice" -and [string]::IsNullOrEmpty($purposeType)) {
    throw "Purpose type must be specified when purpose is SpecialDevice"
}
# Verify permissions for extensionAttribute modifications
Connect-RjRbGraph

<#
# Aus .INPUTS
"username": {
    "DisplayName": "Select the user who will receive the device",
    "Hide":false
    },
    
    
Write-Output '## Checking if user exists'
$Select = 'id,onPremisesDistinguishedName'
$Select
$User = Invoke-RjRbRestMethodGraph -Resource "/users/$username" -OdSelect $Select -ErrorAction SilentlyContinue
if ($null -eq $User) {
    throw ('User "{0}" not found.' -f $username)
}

$User.onPremisesDistinguishedName
$matches = [regex]::matches($User.onPremisesDistinguishedName, '\bOU=[^,]+') | % { $_.value }
$Matches
$Location = $Matches[-2].TrimStart('OU=')
#>

Write-Output '## Checking if device exists'
$D = Invoke-RjRbRestMethodGraph -Resource "/devices/$device" -ErrorAction SilentlyContinue
if ($null -eq $D) {
    throw ('Device "{0}" not found.' -f $device)
}
$D | ConvertTo-Json
#region Set extensionAttribute
$Body = @{
    extensionAttributes = @{
        extensionAttribute1 = $Location
        extensionAttribute2 = $purpose

    }
}
if ($purposeType) {
    $Body.extensionAttributes.extensionAttribute3 = $purposeType
} else {
    $Body.extensionAttributes.extensionAttribute3 = $null
}
$Body | ConvertTo-Json
Write-Output '## Setting extension attributes for device'
Invoke-RjRbRestMethodGraph -Resource "/devices/$device" -Body $Body -Method PATCH

#endregion Set extensionAttribute



