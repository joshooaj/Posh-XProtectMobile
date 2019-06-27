function Remove-MobileServerCertificate {
    [CmdletBinding()]
    param ()
    process {
        $mosInfo = Get-MobileServerInfo -Verbose:$VerbosePreference
        $ipPort = "$($mosInfo.HttpsIp):$($mosInfo.HttpsPort)"
        if ($mosInfo.CertHash) {
            $result = netsh http delete sslcert ipport=$ipPort
            if ($result -notcontains 'SSL Certificate successfully deleted') {
                Write-Warning "Unexpected result from netsh http delete sslcert: $result"
            }
            Restart-Service -Name 'Milestone XProtect Mobile Server' -Verbose:$VerbosePreference
        } else {
            Write-Warning "No sslcert binding present for $ipPort"
        }
    }

    <#
    .SYNOPSIS
        Removes the current sslcert binding for Milestone XProtect Mobile Server

    .DESCRIPTION
        Removes the current sslcert binding for Milestone XProtect Mobile Server. The current
        binding is found by calling Get-MobileServerInfo, and if the CertHash value is -ne $null
        we call netsh http delete sslcert ipport=$HttpsIp:$HttpsPort.
    #>
}