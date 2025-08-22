<#
  .SYNOPSIS
  List all owners of the Microsoft365 groups in which the user is a member.

  .DESCRIPTION
  List all owners of the Microsoft365 groups in which the user is a member.

  .NOTES
  Permissions
   MS Graph (API): 
   - User.Read.All
   - Group.Read.All

  .INPUTS
  RunbookCustomization: {
        "Parameters": {
            "UserName":{
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
    [String] $UserName,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory = $true)]
    [string] $CallerName
)

Write-RjRbLog -Message "Caller: '$CallerName'" -Verbose

$Version = "1.0.0"
Write-RjRbLog -Message "Version: $Version" -Verbose

Connect-RjRbGraph

$User = Invoke-RjRbRestMethodGraph -Resource "/users/$UserName"

# Hole die Gruppen des Benutzers
$groups = Invoke-RjRbRestMethodGraph -Method GET -Resource "/users/$($user.Id)/memberOf" | 
Where-Object { $_.'@odata.type' -eq '#microsoft.graph.group' -and $_.grouptypes -eq 'Unified'}

# Erstelle eine Liste, um die Besitzerinformationen zu speichern
$ownersList = @()

# Hole die Besitzerinformationen für jede Gruppe
foreach ($group in $groups) {
    $owners = Invoke-RjRbRestMethodGraph -Method GET -Resource "/groups/$($group.id)/owners"
    foreach ($owner in $owners) {
        $ownerDetails = Invoke-RjRbRestMethodGraph -Resource "/users/$($owner.id)"
        $ownersList += [PSCustomObject]@{
            GroupName   = $group.displayName
            FirstName   = $ownerDetails.GivenName
            LastName    = $ownerDetails.Surname
            Email       = $ownerDetails.Mail
        }
    }
}

# Ausgabe der Besitzerinformationen
$ownersList | format-table | out-string
