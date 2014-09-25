#
# Module 'Dynamite.PowerShell.Toolkit'
# Generated by: GSoft, Team Dynamite.
# Generated on: 10/24/2013
# > GSoft & Dynamite : http://www.gsoft.com
# > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
# > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
#

<#
.SYNOPSIS
	Replaces tokens in all child items with the file extention .template recursively.
	
.DESCRIPTION
	Replaces tokens in all child items with the file extention .template recursively.
	The template item is copied with without the .template extention before the tokens are replaced.
	The tokens are defined in a 'Tokens.Domain.ps1' file.
	Please define tokens as valiables with the prefix 'DSP_'. 
	EX.: $DSP_token1 = "Value 1" will replace [[DSP_token1]] in any .template file
	
    --------------------------------------------------------------------------------------
    Module 'Dynamite.PowerShell.Toolkit'
    by: GSoft, Team Dynamite.
    > GSoft & Dynamite : http://www.gsoft.com
    > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    --------------------------------------------------------------------------------------
    
.PARAMETER Path
	The path where all the files are located. By default the value is the current working location.
	
.PARAMETER Domain
	The prefix for the token file 'Tokens.Domain.ps1'. By default the value is the current NetBIOS name.
        
  .LINK
    GSoft, Team Dynamite on Github
    > https://github.com/GSoft-SharePoint
    
    Dynamite PowerShell Toolkit on Github
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    
    Documentation
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    
#>
function Update-DSPTokens {
	Param (
		[Parameter(Mandatory=$false, ValueFromPipeline=$true)]
		[ValidateScript({Test-Path $_})]
		[string]$Path = (Get-Location),
		
		[Parameter(Mandatory=$false)]
		[string]$Domain = [System.Net.Dns]::GetHostName(),
		
		[Parameter(Mandatory=$false)]
		[switch]$UseHostName,
		
		[Parameter(Mandatory=$false)]
		[switch]$UseDomain
	)
	
	if ($UseHostName -eq $true) {
		$Domain = [System.Net.Dns]::GetHostName()
	}
	
	if ($UseDomain -eq $true) {
		$Domain = (Get-CurrentDomain)
	}

	$tokenPath = ""
		
	Get-ChildItem -Path $Path -Include "Tokens.$Domain.ps1" -Recurse | foreach {
		$tokenPath = $_.FullName
	}
	
	if (Test-Path $tokenPath) {
		Write-Host "Found token file at : $tokenPath"
		Execute-TokenFile $Path $tokenPath
	}
	else {
		Write-Host "Didn't found the token file named : Tokens.$Domain.ps1"
	}
}

<#
.SYNOPSIS
	Returns the current domain name using wmi. If wmi is not installed, 
	then use the USERDOMAIN environment variable.
#>
function script:Get-CurrentDomain {
	try {
		# Return this version if wmi is installed
		return [string](gwmi Win32_NTDomain).DomainName.Trim()
	} catch {
		# Fall back on this version in case of error
		return $env:USERDOMAIN
	}
}

function script:Execute-TokenFile {
	param (
		$Path,
		$TokenPath
	)
	Write-Host "$TokenPath"
	# Load tokens
	. $TokenPath
	$tokens = Get-Variable -Include "DSP_*"
	
	# Replace tokens in all .template files.
	Get-ChildItem -Path $Path -Include "*.template" -Recurse | foreach {
		Write-Host "Replacing tokens in file '$_'... " -NoNewline
		
		try {
			# Get the contents of the template file.
			$contents  = Get-Content $_ -Encoding UTF8 -ErrorAction Stop
			
			# for each token in our token file, we replace the token in the contents of the file.
			$tokens | ForEach {
				$contents = $contents -replace "\[\[$($_.Name)\]\]", $_.Value
			}
			
			# Write the contents with the replaces tokens to a new file overiding any current file.
			Set-Content -Encoding UTF8 -Value $contents -path $_.FullName.Substring(0, $_.FullName.IndexOf(".template")) -Force -ErrorAction Stop
		} catch {
			Write-Host "Failed - $_" -ForegroundColor Red
		}
		
		Write-Host "Success!" -ForegroundColor Green
	}
}