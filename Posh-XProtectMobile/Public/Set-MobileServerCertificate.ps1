function Set-MobileServerCertificate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        [parameter(ValueFromPipeline=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $X509Certificate,

        [parameter(Position = 1, ValueFromPipelineByPropertyName=$true)]
        [string]
        $Thumbprint
    )

    begin {
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            throw "This command requires elevation. Please run as administrator."
        }
    }

    process {
        $mosInfo = Get-MobileServerInfo -Verbose:$VerbosePreference
        $ipPort = "$($mosInfo.HttpsIp):$($mosInfo.HttpsPort)"
        $appId = "{00000000-0000-0000-0000-000000000000}"
        $certHash = if ($null -eq $X509Certificate) { $Thumbprint } else { $X509Certificate.Thumbprint }
        Write-Debug $mosInfo
        if ($PSCmdlet.ShouldProcess("Add or update sslcert binding")) {
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
        }

        if ($PSCmdlet.ShouldProcess("Restart-Service ""Milestone XProtect Mobile Server""")) {
            Restart-Service -Name 'Milestone XProtect Mobile Server' -Verbose:$VerbosePreference
        }
    }

    <#
    .SYNOPSIS
        Sets the sslcert binding for Milestone XProtect Mobile Server

    .DESCRIPTION
        Sets the sslcert binding for Milestone XProtect Mobile Server when provided with a certificate,
        an object with a Thumbprint property, or when the -Thumbprint parameter is explicitly provided.

        The Thumbprint must represent a publicly signed and trusted certificate located in
        Cert:\LocalMachine\My where the private key is present.

    .PARAMETER X509Certificate
        A [System.Security.Cryptography.X509Certificates.X509Certificate2] object representing a certificate
        which is present in the path Cert:\LocalMachine\My

    .PARAMETER Thumbprint
        The certificate hash, commonly referred to as Thumbprint, representing a certificate which is present
        in the path Cert:\LocalMachine\My

    .EXAMPLE
        gci Cert:\LocalMachine\My | ? Subject -eq 'CN=mobile.example.com' | Set-MobileServerCertificate

        Gets a certificate for mobile.example.com from Cert:\LocalMachine\My and pipes it to Set-MobileServerCertificate

    .EXAMPLE
        Submit-Renewal | Set-MobileServerCertificate

        Submits an ACME certificate renewal using the Posh-ACME module, and if the certificate is renewed, updates the
        Mobile Server sslcert binding by piping the output to Set-MobileServerCertificate. The Submit-Renewal and New-PACertificate
        cmdlets return an object with a Thumbprint property.

        If using Posh-ACME, you must ensure the New-PACertificate command is executed with elevated permissions, and used with the
        -Install switch so that the new certificate is installed into the Cert:\LocalMachine\My path. If you have done this, then
        subsequent executions of Submit-Renewal from an elevated session under the same user context will result the renewed certs
        being installed as well.
    #>
}