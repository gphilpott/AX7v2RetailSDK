<#
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS.  MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED, 
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.  
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.  
NO TECHNICAL SUPPORT IS PROVIDED.  YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
#>
param (
     [string]$TopologyXmlFilePath = $(Throw "The file name is required!"),
     [string]$SettingsXmlFilePath = $(Throw "The file name is required!"),
     [System.Management.Automation.PSCredential[]]$Credentials,
     [string]$Verbose = $false
)
try
{
    $ScriptDir = split-path -parent $MyInvocation.MyCommand.Path;
    . $ScriptDir\Common-Configuration.ps1
    . $ScriptDir\Common-Database.ps1

	Log-TimedMessage "Starting prerequisite checks."
	if (-not (IsKB2701373-InstalledIfNeeded))
	{
		# issue detected in dot source file. Assuming error/warning was printed already, just exiting. This will exit the main script.
		exit ${global:PrerequisiteFailureReturnCode};
	}

	if (-not (CheckOsVersion-IfDomainController))
	{
		# issue detected in dot source file. Assuming error/warning was printed already, just exiting. This will exit the main script.
		exit ${global:PrerequisiteFailureReturnCode};
	}

	if (-not (Check-IfSqlCmdExists))
	{
		# issue detected in dot source file. Assuming error/warning was printed already, just exiting. This will exit the main script.
		exit ${global:PrerequisiteFailureReturnCode};
	}

    # main
    [xml]$TopologyXml = Expand-VariablesFromSettingsFile $TopologyXmlFilePath $SettingsXmlFilePath
	$dbConfigurationXmlNodeList = $TopologyXml.selectnodes("Settings/Databases/Database")
	$dbConfigurations = Get-DatabaseConfigurationsFromXmlNodeList $TopologyXml $dbConfigurationXmlNodeList;
	$windowsGroupMembershipNodes = $TopologyXml.selectnodes("Settings/WindowsGroupMemberShips/*");
	
	# pre-req checks
	Log-TimedMessage "Starting prerequisite checks..."
	# 1. Verify that all files specified in the topology actually exist
	foreach($dbConfiguration in $dbConfigurations)
	{        
		if(($dbConfiguration.Install -eq "true") -and ($dbConfiguration.InstallationType -eq "SqlScripts"))
		{
			$sqlScriptsFilePaths = $dbConfiguration.InstallationValue
            if([System.IO.Path]::IsPathRooted($sqlScriptsFilePaths) -ne $true)
	        {
		        $sqlScriptsFilePaths = Join-Path $ScriptDir $sqlScriptsFilePaths
	        }
	        if((Test-Path -Path $sqlScriptsFilePaths) -ne $True)
	        {
		        Write-Warning -Message ("DatabaseInstallationSqlScript did not specify a valid value or a file that exists. {0} " -f $sqlScriptsFilePaths)
		        exit ${global:PrerequisiteFailureReturnCode};
	        }
		}
	}
	Log-TimedMessage "Verified that all sql scripts referenced by the topology exist."

	# 3. Check that SQL credentials (if applicable) are passed correctly
	if($Credentials)
	{
		foreach($dbConfiguration in $dbConfigurations)
		{
			if(-not(Validate-UserIsInCredentialsArray -UserName $dbConfiguration.SqlUserName -Credentials $Credentials))
			{
				throw ('Credential for user with name [{0}] was not received. The script cannot continue.' -f $dbConfiguration.SqlUserName)
			}

			$foundCredential = $Credentials | ? { $_.UserName -eq $dbConfiguration.SqlUserName}
			$dbConfiguration.SqlUserPassword = $foundCredential.GetNetworkCredential().Password
		}
		
		Log-TimedMessage "Verified that all SQL credentials are valid."
	}

	# 2. Check that any specified Database server can be pinged (prevents typos)
	foreach($dbConfiguration in $dbConfigurations)
	{
		if(($dbConfiguration.Install -eq "true") -or ($dbConfiguration.DropIfExists -eq "true"))
		{
			if(($dbConfiguration.ServerName -eq $null) -or (($dbConfiguration.ServerName -ilike [string]::Empty) -eq $True))
			{
				Write-Warning -Message "Database server has not been specified."
				exit ${global:PrerequisiteFailureReturnCode};
			}

            try
            {
				if($dbConfiguration.SqlUserName -and $dbConfiguration.SqlUserPassword)
				{
					Execute-Sql -sql "select @@servername" -Server $dbConfiguration.ServerName -variables $null -WindowsAuthentication 0 -Username $dbConfiguration.SqlUserName -Password $dbConfiguration.SqlUserPassword
				}
				else
				{
					Execute-Sql "select @@servername" $dbConfiguration.InstanceName
				}
            }
            catch
            {
				Write-Warning -Message ("Database server ""{0}"" cannot be accessed or queried. Make sure the server name is correct and you have the right permissions to create databases. {1}" -f $dbConfiguration.ServerName,$global:error[0])
				exit ${global:PrerequisiteFailureReturnCode};
            }
		}
	}
	Log-TimedMessage "Verified that all active database servers can be accessed."

	# 3. Check that user name and groups are specified correctly
	foreach($windowsGroupMembershipNode in $windowsGroupMembershipNodes)
	{
		if ($true -eq (StringIsNullOrWhiteSpace $windowsGroupMembershipNode.MachineName))
		{
			Write-Warning -Message ("MachineName has not been specified for WindowsGroupMemberShip node")
			exit ${global:PrerequisiteFailureReturnCode};
		}
		if ($true -eq (StringIsNullOrWhiteSpace $windowsGroupMembershipNode.UserName))
		{
			Write-Warning -Message ("UserName has not been specified for WindowsGroupMemberShip node")
			exit ${global:PrerequisiteFailureReturnCode};
		}
		if ($true -eq (StringIsNullOrWhiteSpace $windowsGroupMembershipNode.GroupName))
		{
			Write-Warning -Message ("GroupName has not been specified for WindowsGroupMemberShip node")
			exit ${global:PrerequisiteFailureReturnCode};
		}
	}
	Log-TimedMessage "Verified that all values for Windows group memberships are valid."
	
	Log-TimedMessage "Done with prerequisite checks."

	# install
	foreach($dbConfiguration in $dbConfigurations)
	{
		if($dbConfiguration.Install -eq "true")
		{
			$sqlServerInstanceName = Get-SqlServerInstanceName $dbConfiguration
			Log-TimedMessage ("Installing a new database with name ""{0}"" on instance ""{1}""" -f $dbConfiguration.DatabaseName, $sqlServerInstanceName);

			$sqlServer = Get-SqlServerInstance $dbConfiguration;
			$foundDatabase = Get-SqlDatabase $sqlServer $dbConfiguration.DatabaseName;
			$maxSqlServerMemoryLimitRatio = $dbConfiguration.MaxSqlServerMemoryLimitRatio;
			if($maxSqlServerMemoryLimitRatio)
			{
				Configure-MaxSqlMemoryLimit -sqlServerInstanceName $sqlServerInstanceName -maxSqlServerMemoryLimitRatio $maxSqlServerMemoryLimitRatio
			}
			if($dbConfiguration.DropIfExists -eq "true" -and $foundDatabase -ne $null)
			{
				Drop-SqlDatabase $sqlServer $foundDatabase
				$foundDatabase = $null
			}

            if($foundDatabase -eq $null)
			{
				if($dbConfiguration.InstallationType -eq "SqlScripts")
				{
					Log-TimedMessage ("Creating new database with name ""{0}"" on instance ""{1}""" -f $dbConfiguration.DatabaseName, $sqlServer.Name)
					Create-SqlDatabase $sqlServer $dbConfiguration.DatabaseName

					$sqlScriptsFilePaths = $dbConfiguration.InstallationValue
					if([System.IO.Path]::IsPathRooted($sqlScriptsFilePaths) -ne $true)
					{
						$sqlScriptsFilePaths = Join-Path $ScriptDir $sqlScriptsFilePaths
					}
                    
                    try
                    {
						if($dbConfiguration.SqlUserName -and $dbConfiguration.SqlUserPassword)
						{
							Execute-SqlFile -file $sqlScriptsFilePaths  -Server $dbConfiguration.ServerName -dbName $dbConfiguration.DatabaseName  -variables $null -WindowsAuthentication 0 -Username $dbConfiguration.SqlUserName -Password $dbConfiguration.SqlUserPassword
						}
						else
						{
							Execute-SqlFile $sqlScriptsFilePaths $sqlServerInstanceName $dbConfiguration.DatabaseName
						}
                    }
                    catch
                    {
                        $databaseObject = Get-SqlDatabase -SqlServer $sqlServer -DatabaseName $dbConfiguration.DatabaseName
                        Drop-SqlDatabase -SqlServer $sqlServer -database $databaseObject
                        throw ("Database ""{0}"" schema creation failed. Make sure the sql script is correct." -f $dbConfiguration.DatabaseName);
                    }
				}
				elseif($dbConfiguration.InstallationType -eq "SqlAspNetMembershipDatabase")
				{
					Create-SqlAspNetMembershipDatabase $dbConfiguration
				}

                $message = ("Database ""{0}"" creation is complete." -f $dbConfiguration.DatabaseName)
			    Log-TimedMessage $message
			}

            $databaseObject = Get-SqlDatabase -SqlServer $sqlServer -DatabaseName $dbConfiguration.DatabaseName

            $databaseFilesMinSizeInMB = $dbConfiguration.DatabaseFilesMinSizeInMB
            if($databaseFilesMinSizeInMB)
            {
                Configure-DatabaseFilesMinSize -Database $databaseObject -MinSizeInMB $databaseFilesMinSizeInMB
            }
            
            $databaseFilesGrowthRateInPercent = $dbConfiguration.DatabaseFilesGrowthRateInPercent
            if($databaseFilesGrowthRateInPercent)
            {
                Configure-DatabaseFilesGrowth -Database $databaseObject -GrowthType 'Percent' -GrowthRate $databaseFilesGrowthRateInPercent
            }
            
            $databaseAutoClose = $dbConfiguration.DatabaseAutoClose
            # Need to do null check to see whether value was set at all.
            if($databaseAutoClose -ne $null)
            {
                Set-DatabaseAutoClose -Database $databaseObject -AutoCloseValue $databaseAutoClose
            }
            
			$message = ("Applying any applicable upgrade on this database." -f $dbConfiguration.DatabaseName, $sqlServer.Name)
			Log-TimedMessage $message 
                
            try
            {
                if($dbConfiguration.RetailScriptPath)
                {                    
                    if([System.IO.Path]::IsPathRooted($dbConfiguration.RetailScriptPath) -ne $true)
                    {
                        $retailUpgradeScriptRootedPath = Join-Path $scriptDir $dbConfiguration.RetailScriptPath
                    }
                    else
                    {
                        $retailUpgradeScriptRootedPath = $dbConfiguration.RetailScriptPath
                    }
                    
                    if((Test-Path -Path $retailUpgradeScriptRootedPath) -eq $True)
                    {
                        $retailUpgrades = Get-RetailUpgradeScripts -ScriptsFolderPath $retailUpgradeScriptRootedPath

                        if($retailUpgrades)
                        {
                            Apply-RetailUpgradeScripts -RetailUpgrades $retailUpgrades `
                                                       -SqlServerInstanceName $sqlServerInstanceName `
                                                       -DatabaseName $dbConfiguration.DatabaseName `
                                                       -UserName $dbConfiguration.SqlUserName `
                                                       -Password $dbConfiguration.SqlUserPassword
                        }
                    }
                }                       

                if($dbConfiguration.CustomScriptPath)
                {
                    if([System.IO.Path]::IsPathRooted($dbConfiguration.CustomScriptPath) -ne $true)
                    {
                        $customUpgradeScriptRootedPath = Join-Path $scriptDir $dbConfiguration.CustomScriptPath
                    }
                    else
                    {
                        $customUpgradeScriptRootedPath = $dbConfiguration.CustomScriptPath
                    }

                    if((Test-Path -Path $customUpgradeScriptRootedPath) -eq $True)
                    {
                        $customUpgrades = Get-CustomUpgradeScripts -ScriptsFolderPath $customUpgradeScriptRootedPath

                        if($customUpgrades)
                        {
                            Apply-CustomUpgradeScripts -CustomUpgrades $customUpgrades `
                                                       -SqlServerInstanceName $sqlServerInstanceName `
                                                       -DatabaseName $dbConfiguration.DatabaseName `
                                                       -UserName $dbConfiguration.SqlUserName `
                                                       -Password $dbConfiguration.SqlUserPassword
                        }
                    }
                } 
            }
            catch
            {
                Log-Exception $_        
                Throw-Error ("Database upgrade for database ""{0}"" failed." -f $dbConfiguration.DatabaseName)
            }

            $message = ("Upgrade on database ""{0}"" is complete." -f $dbConfiguration.DatabaseName)
			Log-TimedMessage $message

            if(-not (IsSqlServerAuth -dbConfig $dbConfiguration))
            {
                CreateLoginsUsersAndRoleMembers $dbConfiguration
            }
		} 
		else
		{
			Log-TimedMessage "Skipping database installation."
		}

		$dbConfiguration = $null
	}

	
	# Ensure Windows user groups memberships.
	foreach($windowsGroupMembershipNode in $windowsGroupMembershipNodes)
	{
		AddOrRemoveUserToNTGroup $windowsGroupMembershipNode
	}
	
	# It is important to override the exit code returned by any scripts that were called by the current script.
	# That we made it so far means that none of the errors, if any, were significant enough.
	exit 0
}
catch
{
	Log-Error ($global:error[0] | format-list * -f | Out-String)
    $ScriptLine = "{0}{1}" -f $MyInvocation.MyCommand.Path.ToString(), [System.Environment]::NewLine
	$PSBoundParameters.Keys | % { $ScriptLine += "Parameter: {0} Value: {1}{2}" -f $_.ToString(), $PSBoundParameters[$_.ToString()], [System.Environment]::NewLine}
    $exitCode = 2
	Write-Host ("Executed:{0}$ScriptLine{0}Exiting with error code $exitCode." -f [System.Environment]::NewLine)
	exit $exitCode
}
# SIG # Begin signature block
# MIIdsgYJKoZIhvcNAQcCoIIdozCCHZ8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKA3zG+LXl0vhacfEx+Kkwit7
# YsigghhkMIIEwzCCA6ugAwIBAgITMwAAAJgEWMt/IwmwngAAAAAAmDANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwMzMwMTkyMTI3
# WhcNMTcwNjMwMTkyMTI3WjCBszELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNO
# OjdBRkEtRTQxQy1FMTQyMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1jclqAQB7jVZ
# CvOuH5jFixrRTGFtwMHws1sEZaA3ciobVIdWIejc5fBu3XdwRLfxjsmyou3JeTaa
# 8lqA929q2AyZ9A3ZBfxf8VqTxbu06wBj4o4g5YCsz0C/81N2ESsQZbjDxbW5sKzD
# hhT0nTzr82aepe1drjT5dvyU/AvEkCzaEDU0dZTq2Bm6NIif11GzA+OkD0bdZG+u
# 4EJRylQ4ijStGgXUpAapb0y2RtlAYvZSpLYzeFFcA/yRXacCnoD++h9r66he/Scv
# Gfd/J/5hPRCtgsbNr3vFJzBWgV9zVqmWOvZBPGpLhCLglTh0stPa/ZxZjTS/nKJL
# a7MZId131QIDAQABo4IBCTCCAQUwHQYDVR0OBBYEFPPCI5/SvSWNvaj1nBvoSHO7
# 6ZPBMB8GA1UdIwQYMBaAFCM0+NlSRnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsG
# AQUFBzAChjxodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFRpbWVTdGFtcFBDQS5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQEFBQADggEBAD+xPVIhFl30XEe39rlgUqCCr2fXR9o0aL0Oioap6LAUMXLK
# 4B+/L2c+BgV32joU6vMChTaA+7XEw7pXCRN+uD8ul4ifHrdAOEEqOTBD7N5203u2
# LN667/WY71purP2ezNB1y+YAgjawEt6VjjQcSGZ9bTPRtS2JPS5BS868paym355u
# 16HMxwmhlv1klX6nfVOs1DYK5cZUrPAblCZEWzGab8j9d2ZIGLQmTEmStdslOq79
# vujEI0nqDnJBusUGi28Kh3Hz1QIHM5UZg/F5sWgt0EobFGHmk4KH2vreGZArtCIB
# amDc5cIJ48na9GfA2jqJLWsbvNcwC486g5cauwkwggYHMIID76ADAgECAgphFmg0
# AAAAAAAcMA0GCSqGSIb3DQEBBQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAX
# BgoJkiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMx
# MzAzMDlaMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAf
# BgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAJ+hbLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn
# 0UytdDAgEesH1VSVFUmUG0KSrphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0
# Zxws/HvniB3q506jocEjU8qN+kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4n
# rIZPVVIM5AMs+2qQkDBuh/NZMJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YR
# JylmqJfk0waBSqL5hKcRRxQJgp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54
# QTF3zJvfO4OToWECtR0Nsfz3m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8G
# A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsG
# A1UdDwQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJg
# QFYnl+UlE/wq4QpTlVnkpKFjpGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcG
# CgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3Qg
# Q2VydGlmaWNhdGUgQXV0aG9yaXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJ
# MEcwRaBDoEGGP2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1
# Y3RzL21pY3Jvc29mdHJvb3RjZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYB
# BQUHMAKGOGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9z
# b2Z0Um9vdENlcnQuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEB
# BQUAA4ICAQAQl4rDXANENt3ptK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1i
# uFcCy04gE1CZ3XpA4le7r1iaHOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+r
# kuTnjWrVgMHmlPIGL4UD6ZEqJCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGct
# xVEO6mJcPxaYiyA/4gcaMvnMMUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/F
# NSteo7/rvH0LQnvUU3Ih7jDKu3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbo
# nXCUbKw5TNT2eb+qGHpiKe+imyk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0
# NbhOxXEjEiZ2CzxSjHFaRkMUvLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPp
# K+m79EjMLNTYMoBMJipIJF9a6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2J
# oXZhtG6hE6a/qkfwEm/9ijJssv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0
# eFQF1EEuUKyUsKV4q7OglnUa2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng
# 9wFlb4kLfchpyOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TCCBhAwggP4
# oAMCAQICEzMAAABkR4SUhttBGTgAAAAAAGQwDQYJKoZIhvcNAQELBQAwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTAeFw0xNTEwMjgyMDMxNDZaFw0xNzAx
# MjgyMDMxNDZaMIGDMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MQ0wCwYDVQQLEwRNT1BSMR4wHAYDVQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24w
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCTLtrY5j6Y2RsPZF9NqFhN
# FDv3eoT8PBExOu+JwkotQaVIXd0Snu+rZig01X0qVXtMTYrywPGy01IVi7azCLiL
# UAvdf/tqCaDcZwTE8d+8dRggQL54LJlW3e71Lt0+QvlaHzCuARSKsIK1UaDibWX+
# 9xgKjTBtTTqnxfM2Le5fLKCSALEcTOLL9/8kJX/Xj8Ddl27Oshe2xxxEpyTKfoHm
# 5jG5FtldPtFo7r7NSNCGLK7cDiHBwIrD7huTWRP2xjuAchiIU/urvzA+oHe9Uoi/
# etjosJOtoRuM1H6mEFAQvuHIHGT6hy77xEdmFsCEezavX7qFRGwCDy3gsA4boj4l
# AgMBAAGjggF/MIIBezAfBgNVHSUEGDAWBggrBgEFBQcDAwYKKwYBBAGCN0wIATAd
# BgNVHQ4EFgQUWFZxBPC9uzP1g2jM54BG91ev0iIwUQYDVR0RBEowSKRGMEQxDTAL
# BgNVBAsTBE1PUFIxMzAxBgNVBAUTKjMxNjQyKzQ5ZThjM2YzLTIzNTktNDdmNi1h
# M2JlLTZjOGM0NzUxYzRiNjAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzcitW2oynUC
# lTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEGCCsGAQUF
# BwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
# aW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0MAwGA1Ud
# EwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAIjiDGRDHd1crow7hSS1nUDWvWas
# W1c12fToOsBFmRBN27SQ5Mt2UYEJ8LOTTfT1EuS9SCcUqm8t12uD1ManefzTJRtG
# ynYCiDKuUFT6A/mCAcWLs2MYSmPlsf4UOwzD0/KAuDwl6WCy8FW53DVKBS3rbmdj
# vDW+vCT5wN3nxO8DIlAUBbXMn7TJKAH2W7a/CDQ0p607Ivt3F7cqhEtrO1Rypehh
# bkKQj4y/ebwc56qWHJ8VNjE8HlhfJAk8pAliHzML1v3QlctPutozuZD3jKAO4WaV
# qJn5BJRHddW6l0SeCuZmBQHmNfXcz4+XZW/s88VTfGWjdSGPXC26k0LzV6mjEaEn
# S1G4t0RqMP90JnTEieJ6xFcIpILgcIvcEydLBVe0iiP9AXKYVjAPn6wBm69FKCQr
# IPWsMDsw9wQjaL8GHk4wCj0CmnixHQanTj2hKRc2G9GL9q7tAbo0kFNIFs0EYkbx
# Cn7lBOEqhBSTyaPS6CvjJZGwD0lNuapXDu72y4Hk4pgExQ3iEv/Ij5oVWwT8okie
# +fFLNcnVgeRrjkANgwoAyX58t0iqbefHqsg3RGSgMBu9MABcZ6FQKwih3Tj0DVPc
# gnJQle3c6xN3dZpuEgFcgJh/EyDXSdppZzJR4+Bbf5XA/Rcsq7g7X7xl4bJoNKLf
# cafOabJhpxfcFOowMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkqhkiG9w0B
# AQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAG
# A1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTEw
# HhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBT
# aWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# q/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03a8YS2Avw
# OMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akrrnoJr9eW
# WcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0RrrgOGSsbmQ1
# eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy4BI6t0le
# 2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9sbKvkjh+
# 0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAhdCVfGCi2
# zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8kA/DRelsv
# 1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTBw3J64HLn
# JN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmnEyimp31n
# gOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90lfdu+Hgg
# WCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0wggHpMBAG
# CSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2oynUClTAZ
# BgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/
# BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBaBgNVHR8E
# UzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9k
# dWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsGAQUFBwEB
# BFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9j
# ZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNVHSAEgZcw
# gZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsGAQUFBwIC
# MDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABlAG0AZQBu
# AHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKbC5YR4WOS
# mUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11lhJB9i0ZQ
# VdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6I/MTfaaQ
# dION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0wI/zRive
# /DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560STkKxgrC
# xq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQamASooPoI/
# E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGaJ+HNpZfQ
# 7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ahXJbYANah
# Rr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA9Z74v2u3
# S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33VtY5E90Z1W
# Tk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr/Xmfwb1t
# bWrJUnMTDXpQzTGCBLgwggS0AgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcg
# UENBIDIwMTECEzMAAABkR4SUhttBGTgAAAAAAGQwCQYFKw4DAhoFAKCBzDAZBgkq
# hkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGC
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUOK+vGVc8InHPuFEDhvnoc88v/D4wbAYKKwYB
# BAGCNwIBDDFeMFygKoAoAEQAZQBwAGwAbwB5AC0ARABhAHQAYQBiAGEAcwBlAHMA
# LgBwAHMAMaEugCxodHRwOi8vd3d3Lk1pY3Jvc29mdC5jb20vTWljcm9zb2Z0RHlu
# YW1pY3MvIDANBgkqhkiG9w0BAQEFAASCAQA1/Xz/0fJLaA7jKHssSIu7Ye74mAOG
# 6vvVCYZFZLuUeRBxJrFRT7c+eHmcBs99lAvL0BMNZTyoWWc3rtyZYKdmN8kISsPM
# QOtqTumLuio3hYvvyGQ0sSSGt1Nyc4b0N3zDs2Lk2Hh+fZfBcQw6q7vf64D7CVzD
# PVjnlIHgyesBdfM2lqyfJBTTVlXXLlIqfVPBMURO8YQw06dj3pr2sAdG71XJ4lMb
# L8s9refDc/32ivOq8zLK85UXdE0VLu2eieKZ4CdxuOgwiJcI6IWKMcfnTjdHSQOC
# I8SZU6Cb0QcCwn8sU6FVCWejI2ftOE3GY2WhKZWFOnEabnpXf/tgebPuoYICKDCC
# AiQGCSqGSIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQQITMwAAAJgEWMt/IwmwngAAAAAAmDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcN
# AQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTYwNzIxMjEwNjUyWjAj
# BgkqhkiG9w0BCQQxFgQUVIEQU3f5phvFwHBpF6eujMXqL/YwDQYJKoZIhvcNAQEF
# BQAEggEAwj6mFNn6NxpTYYjXJFKRmH4mbXWQkdoP1yukorLd5yoFPRvxjcwZzBoK
# QSJO4NxYbGdrKlmSQ2zdDCXRi5rOSgFxV8oojjRSxq1XMEXWA6ybbq1nh709Vm7N
# ymNG6/tVp5n+PotKWoOVTvl7LSsQCeBFOwLUZlLIrugbQ0yfAhpze7OCpZPnSIsP
# dqf5fCBRI6gczh+raNy7HUl8MALe5dFPrSkWPTRWYBOWmCODDhVfHTSjDxtRQCdD
# Q/GQHcfomKB4AnJi5NPFDwditjhQ+qu6rJwVFMPJ1JT4ONNcA3/eT4DVtT6RX2AZ
# tLrrZWB5GT7bGkFKmx0euyHBMBW2IQ==
# SIG # End signature block
