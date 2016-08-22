#########################################################################
#  This script is only to fix the compatibility issue between the old deployment (deploy.ps1) and the new DSC deployment, once the deployment is switched, this script will be retired.
##########################################################################

param
(
    [ValidateNotNullOrEmpty()]
    [string]$servicemodelxml = $(Throw 'servicemodelxml is required!'),

    [ValidateNotNullOrEmpty()]
    [string]$log = $(Throw 'log is required!')
)

# Read Service model xml
$global:decodedservicemodelxml=[xml] [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($servicemodelxml))
$ConfigurePrerequisites=$global:decodedservicemodelxml.SelectSingleNode("//Configuration/Setting[@Name='ConfigurePrerequisites']")

if ($ConfigurePrerequisites -eq $null -or $ConfigurePrerequisites.getAttribute("Value") -eq $false)
{
    Write-Output 'ConfigurePrerequisites is set to false, will skip retail post configuration for DSC deployment now'
    return
}

$ScriptDir = split-path -parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'Common-Configuration.ps1')
. (Join-Path $ScriptDir 'Common-Web.ps1')
. (Join-Path $ScriptDir 'Common-Database.ps1')

$global:logfile= $log
$global:logdir=[System.IO.Path]::GetDirectoryName($log)

$TestAssetsRoot=$global:decodedservicemodelxml.SelectSingleNode("//Configuration/Setting[@Name='TestAssetsRoot']").getAttribute("Value")
$WebsiteSslCertificateThumbprint = $global:decodedservicemodelxml.SelectSingleNode("//Configuration/Setting[@Name='WebsiteSslCertificateThumbprint']").getAttribute("Value")
$RetailChannelDatabaseName = $global:decodedservicemodelxml.SelectSingleNode("//Configuration/Setting[@Name='RetailChannelDatabaseName']").getAttribute("Value")

# Update rs url in test config files.
$DSCRetailServerPath = "https://usnconeboxax1ret.cloud.onebox.dynamics.com/Commerce"
$DSCCommerceServerPath = "https://usnconeboxax1ret.cloud.onebox.dynamics.com/Auth"
$DSCRetailServerHealthCheckUrl = "https://usnconeboxax1ret.cloud.onebox.dynamics.com/HealthCheck"

$FunctionalTestsConfig = "$TestAssetsRoot\frameworks\retail\components\apps\platform\pos\sharedapp.functionaltests\Infrastructure\Configuration\FunctionalTestsConfig.json"
if (Test-Path -Path $FunctionalTestsConfig)
{
    Write-Output "updating $FunctionalTestsConfig"
    $jsonConfig = Get-Content $FunctionalTestsConfig -Raw | ConvertFrom-Json
    $jsonConfig.RetailServerUrl = $DSCRetailServerPath
    $jsonConfig | ConvertTo-Json | Out-File -Encoding 'utf8' $FunctionalTestsConfig -Force
}

$TestDeviceFilesToUpdate = @(
     "$TestAssetsRoot\frameworks\retail\components\apps\web\pos\web.uiautomation.windows.headless.functionaltests\TestStoresAndDevices.xml"
    ,"$TestAssetsRoot\frameworks\retail\components\apps\web\pos\web.uiautomation.windows.ie.functionaltests\TestStoresAndDevices.xml"
    )

foreach ($testDeviceConfig in $TestDeviceFilesToUpdate)
{
    if (Test-Path -Path $testDeviceConfig)
    {
        Write-Output "updating $testDeviceConfig"
        $testDeviceConfigDoc = [xml] (Get-Content $testDeviceConfig)
        $testDeviceConfigDoc.ArrayOfTestInfrastructure.TestInfrastructure.RetailServerUrl = $DSCRetailServerPath
        $testDeviceConfigDoc.ArrayOfTestInfrastructure.TestInfrastructure.CommerceServerUrl = $DSCCommerceServerPath
        $testDeviceConfigDoc.Save($testDeviceConfig)
    }
}

$TestConfigsWithAppSettingsToUpdate = @(
     "$TestAssetsRoot\frameworks\retail\components\platform\libraries\proxies\retailproxy.anonymous.rs.sqlserver.functionaltests\MS.Dynamics.Commerce.RetailProxy.Anonymous.RS.SqlServer.FunctionalTests.dll.config"
    ,"$TestAssetsRoot\frameworks\retail\components\platform\libraries\proxies\retailproxy.customer.rs.sqlserver.functionaltests\MS.Dynamics.Commerce.RetailProxy.Customer.RS.SqlServer.FunctionalTests.dll.config"
    ,"$TestAssetsRoot\frameworks\retail\components\platform\libraries\proxies\retailproxy.employee.chained.sqlserver.functionaltests\MS.Dynamics.Commerce.RetailProxy.Employee.Chained.SqlServer.FunctionalTests.dll.config"
    ,"$TestAssetsRoot\frameworks\retail\components\platform\libraries\proxies\retailproxy.employee.crt.sqlite.functionaltests\MS.Dynamics.Commerce.RetailProxy.Employee.CRT.Sqlite.FunctionalTests.dll.config"    
    ,"$TestAssetsRoot\frameworks\retail\components\platform\libraries\proxies\retailproxy.employee.crt.sqlserver.functionaltests\MS.Dynamics.Commerce.RetailProxy.Employee.CRT.SqlServer.FunctionalTests.dll.config"
	,"$TestAssetsRoot\frameworks\retail\components\platform\libraries\proxies\retailproxy.employee.rs.sqlserver.functionaltests\MS.Dynamics.Commerce.RetailProxy.Employee.RS.SqlServer.FunctionalTests.dll.config"
	,"$TestAssetsRoot\frameworks\retail\components\platform\libraries\proxies\retailproxy.employee.demomode.sqlserver.functionaltests\MS.Dynamics.Commerce.RetailProxy.Employee.DemoMode.SqlServer.FunctionalTests.dll.config"
    ,"$TestAssetsRoot\Common\Team\Application\Retail\MS.Dynamics.Commerce.RetailProxy.Employee.RS.SqlServer.FunctionalTests.dll.config"
    )

foreach ($testConfig in $TestConfigsWithAppSettingsToUpdate)
{
    if (Test-Path -Path $testConfig)
    {
        Write-Output "updating $testConfig"
        $testConfigDoc = [xml] (Get-Content $testConfig)
		
		if($testConfigDoc.SelectSingleNode("//configuration/appSettings/add[@key='RetailServerUrl']"))
		{
			$testConfigDoc.SelectSingleNode("//configuration/appSettings/add[@key='RetailServerUrl']").SetAttribute('value',$DSCRetailServerPath)
        }
		if($testConfigDoc.SelectSingleNode("//configuration/appSettings/add[@key='CommerceAuthenticationUrl']"))
		{
			$testConfigDoc.SelectSingleNode("//configuration/appSettings/add[@key='CommerceAuthenticationUrl']").SetAttribute('value',$DSCCommerceServerPath)
        }
		if($testConfigDoc.SelectSingleNode("//configuration/appSettings/add[@key='RetailServerHealthCheckUrl']"))
		{
			$testConfigDoc.SelectSingleNode("//configuration/appSettings/add[@key='RetailServerHealthCheckUrl']").SetAttribute('value',$DSCRetailServerHealthCheckUrl)
		}
		
		Write-Output "updating connection string"
		foreach($connectionstring in $testConfigDoc.SelectNodes("//configuration/connectionStrings/add"))
		{
			$connectionstring.connectionString = ("Data Source=(local);Initial Catalog={0};Integrated Security=True;Persist Security Info=False;Pooling=True;Encrypt=True;TrustServerCertificate=True" -f $RetailChannelDatabaseName)
		}
		
        $testConfigDoc.Save($testConfig)
    }
}

# Update Retail Server web.config to allow anonymous access
$RetailServerWebRootReg = Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Dynamics\7.0\RetailServer\RetailServer\" -Name "ServiceInstallFolder"
$RetailServerWebRootPath = (Join-Path $RetailServerWebRootReg.ServiceInstallFolder 'web.config')

if(Test-Path -Path $RetailServerWebRootPath)
{
	$RetailServerWebConfigDoc = [xml] (Get-Content $RetailServerWebRootPath)
	$RetailServerWebConfigDoc.SelectSingleNode("//configuration/appSettings/add[@key='IsAnonymousEnabled']").SetAttribute('value','true')
	
	$RetailServerWebConfigDoc.Save($RetailServerWebRootPath)
}

# Update RTS test config
# "C:\Test\DVD1\frameworks\retail\components\platform\libraries\cdx\realtimeservice.functionaltests\MS.Dynamics.Retail.RealtimeService.FunctionalTests.dll.config"
$RTSTestConfigPath = "$TestAssetsRoot\frameworks\retail\components\platform\libraries\cdx\realtimeservice.functionaltests\MS.Dynamics.Retail.RealtimeService.FunctionalTests.dll.config"
if(Test-Path -Path $RTSTestConfigPath)
{
	$RTSTestConfigDoc = [xml] (Get-Content $RTSTestConfigPath)
	$RTSTestConfigDoc.SelectSingleNode("//configuration/appSettings/add[@key='SigningCertificateThumbprint']").SetAttribute('value',$WebsiteSslCertificateThumbprint)
	
	$RTSTestConfigDoc.Save($RTSTestConfigPath)
}

# Rebuild full text search
Execute-SqlFile -file (Join-Path $ScriptDir 'RebuildFullTextCatalogAndWait.sql') -server 'localhost' -dbName $RetailChannelDatabaseName

# Update registry to handle legacy cloud pos test case.
$CloudPosWebRoot = Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Dynamics\7.0\RetailCloudPos\RetailCloudPos\" -Name "ServiceInstallFolder"
$CloudPosRegistryKeyName = "HKLM:SOFTWARE\Microsoft\Dynamics\7.0\CloudPos\CloudPos\"
[void](New-Item $CloudPosRegistryKeyName -Force)
[void](New-ItemProperty -Path $CloudPosRegistryKeyName -Name "ServiceInstallFolder" -PropertyType "String" -Value $CloudPosWebRoot.ServiceInstallFolder -Force)
# SIG # Begin signature block
# MIId4wYJKoZIhvcNAQcCoIId1DCCHdACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0+pGkMt50PYhwe/xhNsDW+e0
# ZiygghhkMIIEwzCCA6ugAwIBAgITMwAAAK7sP622i7kt0gAAAAAArjANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwNTAzMTcxMzI1
# WhcNMTcwODAzMTcxMzI1WjCBszELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNO
# OkI4RUMtMzBBNC03MTQ0MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxTU0qRx3sqZg
# 8GN4YCrqA1CzmYPp8+U/MG7axHXPZGdMvNbRSPl29ba88jCYRut/6p5OjvCGNcRI
# MPWKFMqKVeY8zUoQNp46jYsXenl4vTAgJ2cUCeaGy9vxLYTGuXtaChn+jIpPuR6x
# UQ60Y44M2jypsbcQZYc6Oukw4co+CIw8fKqxPcDjdm1c/gyzVnhSYTXsv8S0NBwl
# iuhNCNE4D8b0LNj7Exj5zfVYGvP6Z+JtGY7LT+7caUCT0uItKlE0D/iDvlY5zLrb
# luUb4WLUBpglMw7bU0BSAcvcNx0XyV7+AdcmhiFQGt4pZjbVzOsXs3POWHTq4/KX
# RmtGHKfvMwIDAQABo4IBCTCCAQUwHQYDVR0OBBYEFBw4ctJakrpBibpB9TJkYJsJ
# gGBUMB8GA1UdIwQYMBaAFCM0+NlSRnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsG
# AQUFBzAChjxodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFRpbWVTdGFtcFBDQS5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQEFBQADggEBAAAZsVbJVNFZUNMcXRxKeelc1DgiQHLC60Sika98OwDFXomY
# akk6yvE+fJ3DICnDUK9kmf83sYTOQ5Y7h3QzwHcPdyhLPHSBBmuPklj6jcWGuvHK
# pUuP9PTjyKBw0CPZ1PTO1Jc5RjsQYvxqu01+G5UvZolnM6Ww7QpmBoDEyze5J+dg
# GwrWMhIKDzKLV9do6R5ouZQvLvV7bjH50AX2tK2n3zpZYvAl/LayLHFNIO7A2DQ1
# VzWa3n2yyYvameaX1NkSLA32PqjAXykmkDfHQ6DFVuDV4nqrNI+s14EJgMQy8DzU
# 9X7+KIkCzLFNq/bc2WDo15qsQiACPVSKY1IOGiIwggYHMIID76ADAgECAgphFmg0
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
# bWrJUnMTDXpQzTGCBOkwggTlAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcg
# UENBIDIwMTECEzMAAABkR4SUhttBGTgAAAAAAGQwCQYFKw4DAhoFAKCB/TAZBgkq
# hkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGC
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUYbCV1BsqQLlkmVeCdMj8DAWmU88wgZwGCisG
# AQQBgjcCAQwxgY0wgYqgWIBWAFIAZQB0AGEAaQBsAFAAbwBzAHQAQwBvAG4AZgBp
# AGcAdQByAGEAdABpAG8AbgBGAG8AcgBEAFMAQwBEAGUAcABsAG8AeQBtAGUAbgB0
# AC4AcABzADGhLoAsaHR0cDovL3d3dy5NaWNyb3NvZnQuY29tL01pY3Jvc29mdER5
# bmFtaWNzLyAwDQYJKoZIhvcNAQEBBQAEggEAQuoESUK+5rbsCCjr6x6EWxhlee8w
# CYy6QYog3ql+a2HQmyWsRXOZE+aVLjayrAAeB9SNNGZtUYdjR9dLSpl6HFHj7e7O
# 044zUHt0c5zkRrRRr9ihmLIl2uRc7mlnVC8cVd/97ND9xvaK+YrSV7FGCE1JlgvB
# YvDd0qm4ubxt65s2VjSdaZws6UBH5FhXz6iRuTD9Q8AvjtW+7RPmE466CZ9mHtrX
# 2rVtsP7IQh8Y4zx5Z5FkJMrR/VoIr5k0lOMLOYcAlsthEzoB0aqAFNwJd2zfMGrC
# ZgZepbNP4buYReYxRya8siP6ZaOoUsI2hkVx5pekasXWpOTmVFv/xgh+q6GCAigw
# ggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFt
# cCBQQ0ECEzMAAACu7D+ttou5LdIAAAAAAK4wCQYFKw4DAhoFAKBdMBgGCSqGSIb3
# DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE2MDcyMTIxMDcxOFow
# IwYJKoZIhvcNAQkEMRYEFHwmLjDv1xfHngmZYW5MSw0zYbm2MA0GCSqGSIb3DQEB
# BQUABIIBAH4Xa6KULtC2ItBaFZvUJ2GiUepQ+U2QniHeoSdHcTrUHU55bdiwx3K4
# RMB2cHsRu7o6/9uEbnyPbsdo7TO8UkYz3SBtp+PpuSh1lT0gVqnV5fu7ahZyW7BJ
# SrMAYrz0QJn2rYb9SQT8G19KKaiejiF9T+Cg9u9JQEgirKQFfBG7+uKMqhIEyHza
# +vm9PSD8UFlPhjrd5co/qsXcjCdDTJGWrJp/n/XdVpQ/1VzP0DcE488V82DcKb8C
# lfvSD0jqaBaF2xkpPaGMOn4EBMzTzgaCZELTIbZdWIPeu/JbUtXK+jizy5ipxIJ0
# ZwxBoVpx8ZyKf0/rE/JK5/DkFZpVuUI=
# SIG # End signature block