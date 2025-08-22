<#
  .SYNOPSIS
  Reset the assignment to the WindowsClient-App Standard apps.

  .DESCRIPTION
  Reset the assignment to the WindowsClient-App Standard apps.

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
    #[Parameter(Mandatory = $true)]
    [String] $UserName,
    # CallerName is tracked purely for auditing purposes
    #[Parameter(Mandatory = $true)]
    [string] $CallerName
)

Write-RjRbLog -Message "Caller: '$CallerName'" -Verbose

$Version = "1.0.0"
Write-RjRbLog -Message "Version: $Version" -Verbose

'## Start script'
Connect-RjRbGraph
'## Checking if user exists'
$Select = 'id,onPremisesDistinguishedName'
$User = Invoke-RjRbRestMethodGraph -Resource "/users/$username" -OdSelect $Select -ErrorAction SilentlyContinue
if ($null -eq $User) {
    throw ('User "{0}" not found.' -f $username)
}

$User.onPremisesDistinguishedName
$MA = [regex]::matches($User.onPremisesDistinguishedName, '\bOU=[^,]+') | ForEach-Object {$_.value}
$Location = $MA[-2].TrimStart('OU=')
'Location: {0}' -f $Location

$groupid = 
switch ($Location) {
    ALM {'31a45994-38af-4525-aab0-a6da9862e435'}
    ANT {'8db61570-2490-4cb0-b7e4-b54b73bf792c'}
    BAR {'590fe086-0111-4344-ba74-0bf266b6c237'}
    BAS {'4814549e-fa7c-4d21-a8c5-40d4a0bbf164'}
    #BER {'6a993402-a286-405a-9e1c-5990282957dd'}
    BRA {'6b31cbab-0c9d-4899-ab60-09d680ce33c9'}
    BRO {'97d31776-54f2-4a9c-b656-bb8d4d7d4ece'}
    BUD {'7d0b0595-3696-4c69-b91e-39da8b52e79b'}
    CHI {'6c67f09f-11b5-499a-80f1-f81b5751fcf1'}
    DUB {'eca7e056-8464-4261-99d9-86629019aed8'}
    FLO {'f91cb5f1-e5aa-4335-9660-ede0a5cf02b4'}
    HAL {'13d12172-bdc3-4439-8f0f-cdab9535bc29'}
    HOE {'2a9c21de-808c-4776-880b-a5cf661ee152'}
    LJU {'37221dfd-0ee4-4be8-9956-45d261216863'}
    MIL {'dce03572-648f-4f4a-b1e8-ac0a414493bb'}
    MIS {'aa936709-8ec8-4eb9-9401-37af9c82e74f'}
    MOS {'c5a6fecf-9439-415a-99c8-f815cd6a1c5e'}
    OHR {'2120e709-af77-4097-96c0-80dcef38b8eb'}
    PAR {'3e76e949-e5e5-4ab9-afce-a5c055d5a05d'}
    PRA {'77dbbdcb-7d21-4e6a-bc55-c255f9c4d03b'}
    QUI {'f8e136a8-b9f9-428d-92bf-e8054fe05be2'}
    SAL {'56fad400-55ba-4840-9048-30ea9f1912c9'}
    SAN {'3274ccaf-931b-44ef-8e30-b72157ca5a5e'}
    SDO {'57ab4d4e-d060-4381-bedb-5cee92a07724'}
    SIN {'230f0135-c4b2-4e93-a5eb-e4ebd6e1106b'}
    #TAU {'a0beb5e0-d797-4e23-be62-45dcacfa60eb'}
    WAR {'bfe0ca29-ad89-4f40-a9f4-b9fdef693253'}
    ZAG {'42b43b34-f5f2-447c-9a12-e4483999b0bc'}
    ZUR {'5204f1e0-06cf-46c4-9392-105df980760d'}
    Default {'13d12172-bdc3-4439-8f0f-cdab9535bc29'} # WindowsClient-App - Standard Apps HAL (please do not use this group)
}

'GroupId: {0}' -f $groupid


$StandardGroups = Invoke-RjRbRestMethodGraph -Resource "/groups/$groupid/members" -FollowPaging | Where-Object {$_.displayname -like 'WindowsClient-App *'}
if ($null -eq $StandardGroups) {
    throw ('Groups not found.')
}
$HashStandardGroups = @{}
foreach ($item in $StandardGroups) {
    $HashStandardGroups.add($item.id,$item.displayName)
}


#$filter = 'startswith(displayName, ''WindowsClient-App'')'
$Groups = Invoke-RjRbRestMethodGraph -Resource "/users/$UserName/memberof" -FollowPaging | Where-Object {$_.displayname -like 'WindowsClient-App *'}
if ($null -eq $Groups) {
    throw ('Groups not found.')
}
$HashGroups = @{}
foreach ($item in $Groups) {
    $HashGroups.add($item.id,$item.displayName)
}

$body = @{"@odata.id" = ('https://graph.microsoft.com/v1.0/directoryObjects/{0}' -f $User.id)}

foreach ($item in $HashGroups.GetEnumerator()) {
    If (!$HashStandardGroups[$item.Key]) {
        $Resource = ('/groups/{0}/members/{1}/$ref' -f $item.Key,$User.id)
        Invoke-RjRbRestMethodGraph -Resource $Resource -Method Delete -Body $body | Out-Null
        ('## {0} is removed from {1}' -f $UserName,$item.Value)
    } else {('## skip: {0}' -f $item.Value)
}
}

foreach ($item in $HashStandardGroups.GetEnumerator()) {
    If (!$HashGroups[$item.Key]) {
        $Resource = ('/groups/{0}/members/$ref' -f $item.Key)
        Invoke-RjRbRestMethodGraph -Resource $Resource -Method Post -Body $body | Out-Null
        ('## user is added to {0}' -f $item.Value)      
    }
}
