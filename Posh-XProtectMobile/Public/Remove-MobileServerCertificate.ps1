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
        }
    }
}