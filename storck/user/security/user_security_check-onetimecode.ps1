
<#
  .SYNOPSIS
  Check the OneTimeCode and generate a temporary access pass for a user.

  .DESCRIPTION
  Check the OneTimeCode and generate a temporary access pass for a user.

  .PARAMETER OneTimeCode
  Code you get from the user

  .PARAMETER LifetimeInMinutes
  Time the pass will stay valid in minutes

  .NOTES
  Permissions needed:
  - UserAuthenticationMethod.ReadWrite.All

  .INPUTS
  RunbookCustomization: {
        "Parameters": {
             "UserName": {
                "Hide": false
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
    [String]$UserName,
    [ValidateScript( { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; Use-RJInterface -Type Number -DisplayName "OneTimeCode" } )]
    [int] $OneTimeCode,
    [ValidateScript( { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; Use-RJInterface -Type Number -DisplayName "Lifetime" } )]
    [int] $LifetimeInMinutes = 240,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Write-RjRbLog -Message "Caller: '$CallerName'" -Verbose

$Version = "1.0.0"
Write-RjRbLog -Message "Version: $Version" -Verbose


Connect-RjRbGraph

#region OneTimeCode
'## Check if OneTimeCode is correct'
try {
    $Select = 'customSecurityAttributes'
    $User = Invoke-RjRbRestMethodGraph -Resource "/users/$UserName" -OdSelect $Select
    #'{0} - {1}' -f ($User.customSecurityAttributes.Storck, $User.customSecurityAttributes.Storck.CustomSecurityAttribute1)
    if ($User.customSecurityAttributes.Storck.CustomSecurityAttribute1 -eq $OneTimeCode) {
        'Result:{0} - OneTimeCode:{1} - Attri:{2}' -f $true,$OneTimeCode,$User.customSecurityAttributes.Storck.CustomSecurityAttribute1
    }
    else {
        '## Result:{0} - OneTimeCode:{1} - Attri:{2}' -f $false,$OneTimeCode,$User.customSecurityAttributes.Storck.CustomSecurityAttribute1
        throw
    }
}
catch {
    
    throw ($_)
}
#endregion OneTimeCode

#region TAP

"## Trying to create an Temp. Access Pass (TAP) for user '$UserName'"
try {
    # "Making sure, no old temp. access passes exist for $UserName"
    $OldPasses = Invoke-RjRbRestMethodGraph -Resource "/users/$UserName/authentication/temporaryAccessPassMethods" -Beta
    $OldPasses | ForEach-Object {
        Invoke-RjRbRestMethodGraph -Resource "/users/$UserName/authentication/temporaryAccessPassMethods/$($_.id)" -Beta -Method Delete | Out-Null
    } 
}
catch {
    "Querying of existing Temp. Access Passes failed. Maybe you are missing Graph API permissions:"
    "- 'UserAuthenticationMethod.ReadWrite.All' (API)"
    
    throw ($_) 
}

try {
    
    # "Creating new temp. access pass"
    $body = @{
        "@odata.type"       = "#microsoft.graph.temporaryAccessPassAuthenticationMethod";
        "lifetimeInMinutes" = $LifetimeInMinutes;
        "isUsableOnce"      = $OneTimeUseOnly
    }
    $pass = Invoke-RjRbRestMethodGraph -Resource "/users/$UserName/authentication/temporaryAccessPassMethods" -Body $body -Beta -Method Post 
    
    if ($pass.methodUsabilityReason -eq "DisabledByPolicy") {
        "## Beware: The use of Temporary access passes seems to be disabled for this user."
        ""
    }
    
    "## New Temporary access pass for '$UserName' with a lifetime of $LifetimeInMinutes minutes has been created:" 
    ""
    "$($pass.temporaryAccessPass)"
}
catch {
    "Creation of a new Temp. Access Pass failed. Maybe you are missing Graph API permissions:"
    "- 'UserAuthenticationMethod.ReadWrite.All' (API)"
    throw ($_)
}
#endregion TAP