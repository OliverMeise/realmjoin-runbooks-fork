
<#
  .SYNOPSIS
    Get the authentication methods of a user.

  .DESCRIPTION
    This script retrieves the authentication methods of a user in Microsoft Entra ID.

  .NOTES
    Permissions:
    MS Graph (API):
        - UserAuthenticationMethod.Read.All

  .INPUTS
    RunbookCustomization: {
        "Parameters": {
            "UserId": {
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
    [Parameter(Mandatory)]
    [String]$userid,
    # CallerName is tracked purely for auditing purposes
    [Parameter(Mandatory)]
    [string] $CallerName
)

Write-RjRbLog -Message "Caller: '$CallerName'" -Verbose

$Version = "1.0.0"
Write-RjRbLog -Message "Version: $Version" -Verbose

Connect-RjRbGraph

#region Get Authentication Methods
$Methods = Invoke-RjRbRestMethodGraph -Resource "/users/$userid/authentication/methods"

#endregion Get Authentication Methods

$result = 
foreach ($Method in $Methods)
{
	#$Method

    switch ($Method."@odata.type") 
	{
		'#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'  
		{
			$MethodAuthType     = 'AuthenticatorApp'
			$AdditionalProperties = $Method."displayName"
		}
        
		'#microsoft.graph.phoneAuthenticationMethod'                   
		{
			$MethodAuthType     = 'PhoneAuthentication'
			$AdditionalProperties = ('{0}, {1}' -f $Method."phoneType", $Method."phoneNumber")
		}
        
		'#microsoft.graph.passwordAuthenticationMethod'                
		{
			$MethodAuthType     = 'PasswordAuthentication'
			$AdditionalProperties = $Method."displayName"
		}
        
		'#microsoft.graph.fido2AuthenticationMethod'                   
		{
			$MethodAuthType     = 'Fido2'
			$AdditionalProperties = $Method."model"
		}
        
		'#microsoft.graph.windowsHelloForBusinessAuthenticationMethod' 
		{
			$MethodAuthType     = 'WindowsHelloForBusiness'
			$AdditionalProperties = $Method."displayName"
		}
        
		'#microsoft.graph.emailAuthenticationMethod'                   
		{
			$MethodAuthType     = 'EmailAuthentication'
			$AdditionalProperties = $Method."emailAddress"
		}
        
		'#microsoft.graph.temporaryAccessPassAuthenticationMethod'
		{
			$MethodAuthType     = 'TemporaryAccessPass'
			$AdditionalProperties = ('{0}, {1}' -f $Method.lifetimeInMinutes, $Method."methodUsabilityReason")
		}
        
		'#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod' 
		{
			$MethodAuthType     = 'Passwordless'
			$AdditionalProperties = $Method."displayName"
		}
        
		'#microsoft.graph.softwareOathAuthenticationMethod' 
		{
			$MethodAuthType     = 'SoftwareOath'
			$AdditionalProperties = $Method."displayName"
		}
	}
    
	[PSCustomObject]@{
		AuthenticationMethodId = $Method.Id
		MethodType             = $MethodAuthType
		AdditionalProperties   = $AdditionalProperties
	}
    
}
$result | sort-object -property AuthenticationMethodId | format-table | out-string
