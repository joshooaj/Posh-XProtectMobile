#Requires -RunAsAdministrator

function Start-LECertSetupUsingDynu {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact="Medium")]
    param ()

    process {
        if ((Get-Module Posh-XProtectMobile).Version -lt 0.5) {
            Install-Module Posh-XProtectMobile -Force -Verbose
        }

        $InstallParams = @{
            Domain = Read-Host "Domain name"
            Contact = Read-Host "E-mail address for renewal notifications"
            DnsPlugin = "Dynu"
            PluginArgs = @{
                DynuClientID = Read-Host "Dynu Client ID"
                DynuSecret = Read-Host "Dynu Secret"
            }
            ScriptDirectory = "C:\scripts"
        }

        Install-CertificateAutomation @InstallParams -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
    }

    <#
    .SYNOPSIS
        Initiates the process of installing and configuring full Let's Encrypt certificate automation
        using Dynu DNS for ACME DNS challenge response

    .DESCRIPTION
        Requests information about the domain for the certificate request, and the Dynu DNS API client
        ID/secret. With this information, the following processes take place...

        - Install Posh-ACME if not already available. Posh-ACME interfaces with Let's Encrypt and
        manages the certificate request and DNS challenge request/response

        - Request and install a certificate from the Let's Encrypt staging server

        - If successful, a certificate is requested and installed from the Let's Encrypt production server

        - The new certificate is bound to the Mobile Server and the Mobile Server service is restarted

        - A script is created in C:\scripts

        - A Scheduled Task is created to execute the script in C:\scripts daily. This script will handle
        the certificate renewal process and log the results to C:\scripts\log.txt
    #>
}