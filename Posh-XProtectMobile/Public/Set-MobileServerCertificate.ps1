function Set-MobileServerCertificate {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $X509Certificate,

        [parameter(Position = 1, ValueFromPipelineByPropertyName=$true)]
        [string]
        $Thumbprint
    )
    process {
        $mosInfo = Get-MobileServerInfo -Verbose:$VerbosePreference
        $ipPort = "$($mosInfo.HttpsIp):$($mosInfo.HttpsPort)"
        $appId = "{00000000-0000-0000-0000-000000000000}"
        $certHash = if ($null -eq $X509Certificate) { $Thumbprint } else { $X509Certificate.Thumbprint }
        Write-Debug $mosInfo
        if ($null -eq $mosInfo.CertHash) {
            $result = netsh http add sslcert ipport=$ipPort appid="$appId" certhash=$certHash
            if ($result -notcontains 'SSL Certificate successfully added') {
                Write-Error "Failed to add certificate binding. $result"
                return
            }
            else {
                Write-Verbose [string]$result
            }
        } 
        else {
            $result = netsh http update sslcert ipport=$ipPort certhash=$certHash appid="$appId"
            if ($result -notcontains 'SSL Certificate successfully updated') {
                Write-Error "Failed to update certificate binding. $result"
                return
            }
            else {
                Write-Verbose [string]$result
            }
        }

        Restart-Service -Name 'Milestone XProtect Mobile Server' -Verbose:$VerbosePreference
    }
}