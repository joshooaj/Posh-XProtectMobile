function Remove-MobileServerCertificate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param ()

    begin {
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            throw "This command requires elevation. Please run as administrator."
        }
    }

    process {
        $mosInfo = Get-MobileServerInfo -Verbose:$VerbosePreference
        $ipPort = "$($mosInfo.HttpsIp):$($mosInfo.HttpsPort)"

        if (!($mosInfo.CertHash)) {
            Write-Warning "No sslcert binding present for $ipPort"
            return
        }

        if ($PSCmdlet.ShouldProcess("Delete sslcert binding for ipport=$ipPort")) {
            $result = netsh http delete sslcert ipport=$ipPort
            if ($result -notcontains 'SSL Certificate successfully deleted') {
                Write-Warning "Unexpected result from netsh http delete sslcert: $result"
            }
        }

        if ($PSCmdlet.ShouldProcess("Restart-Service ""Milestone XProtect Mobile Server""")) {
            Restart-Service -Name 'Milestone XProtect Mobile Server' -Verbose:$VerbosePreference
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