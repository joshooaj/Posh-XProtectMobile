function Install-CertificateAutomation {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact="Medium")]
    param (
        [Parameter(Mandatory, Position = 1)]
        [string]
        $Domain,
        [Parameter(Position = 2)]
        [string]
        $Contact,
        [Parameter(Position = 3)]
        [string]
        $DnsPlugin,
        [Parameter(Position = 4)]
        [hashtable]
        $PluginArgs,
        [Parameter(Position = 5)]
        [string]
        $ScriptDirectory = "C:\scripts"
    )

    begin {
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            throw "This command requires elevation. Please run as administrator."
        }

        Write-Output "Setting Execution Policy to RemoteSigned"
        Set-ExecutionPolicy RemoteSigned -WhatIf:$WhatIfPreference

        if (!(Get-Module Posh-ACME)) {
            Install-Module Posh-ACME -Repository PSGallery -Verbose:$VerbosePreference -WhatIf:$WhatIfPreference
        }
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess("Install test certificate")) {
                Write-Output "Testing certificate request against staging server"
                Set-PAServer LE_STAGE
                New-PACertificate -force $domain -AcceptTOS -Contact $contact -DnsPlugin $DnsPlugin -PluginArgs $PluginArgs -Install -ErrorAction Stop -Verbose:$VerbosePreference
                Write-Output "Successfully installed certificate from staging server"

                Write-Output "Removing test certificate"
                $stagingCert = Get-PACertificate
                Get-ChildItem Cert:\LocalMachine\My | Where-Object Thumbprint -eq $stagingCert.Thumbprint | Remove-Item
            }

            if ($PSCmdlet.ShouldProcess("Install production certificate")) {
                Write-Output "Installing production certificate"
                Set-PAServer LE_PROD
                New-PACertificate -force $domain -AcceptTOS -Contact $contact -DnsPlugin $DnsPlugin -PluginArgs $PluginArgs -Install -ErrorAction Stop -Verbose:$VerbosePreference
                Write-Output "Certificate installed to Cert:\LocalMachine\My"
            }

            if ($PSCmdlet.ShouldProcess("Bind new certificate to Mobile Server")) {
                Write-Output "Binding certificate to Mobile Server"
                Get-PACertificate | Set-MobileServerCertificate -ErrorAction Stop -Verbose:$VerbosePreference
            }

            Write-Output "Setting up automatic certificate renewal script in $ScriptDirectory"
            $scriptPath = Join-Path $ScriptDirectory "renew-certificate.ps1"
            $logPath = Join-Path $ScriptDirectory "log.txt"
            if (!(Test-Path $ScriptDirectory)) {
                New-Item $ScriptDirectory -ItemType Directory -WhatIf:$WhatIfPreference | Out-Null
            }
            $scriptBlock = {
                param([string]$LogPath)
                function WriteLog {
                    Param ([string]$message)
                    Add-Content -Path $LogPath -Value "$(Get-Date) - $message"
                }

                try {

                    $thumbprint = (Get-PACertificate).Thumbprint
                    $cert = Submit-Renewal -WarningAction Stop -ErrorAction Stop
                    $cert | Set-MobileServerCertificate

                    WriteLog "New certificate installed with thumbprint $($cert.Thumbprint)"
                    WriteLog "Removing old certificate with thumbprint $thumbprint"

                    Get-ChildItem Cert:\LocalMachine\My |
                        Where-Object Thumbprint -eq $thumbprint |
                        Remove-Item

                } catch {
                    WriteLog $_.Exception.Message
                    throw
                }
            }
            Set-Content -Path $scriptPath -Value $scriptBlock -WhatIf:$WhatIfPreference

            if ($PSCmdlet.ShouldProcess("Register-ScheduledTask to execute $scriptPath")) {
                Write-Output "Registering a new scheduled task to run the renewal script daily"
                $taskName = 'Posh-ACME Certificate Renewal'
                $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File ""$scriptPath"" $logPath"
                $trigger = New-ScheduledTaskTrigger -Daily -At 2am
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue -WhatIf:$WhatIfPreference
                $credential = Get-Credential -Message "Enter your password to setup the Scheduled Task" -UserName ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
                $taskParams = @{
                    Action = $action
                    Trigger = $trigger
                    TaskName = $taskName
                    RunLevel = "Highest"
                    User = $credential.UserName
                    Password = ($credential.Password | ConvertTo-UnsecureString)
                }
                Register-ScheduledTask @taskParams | Out-Null
                $taskParams = $null
            }

            Write-Output "Adding $domain to the local hosts file"
            $params = @{
                Path = "$($env:SystemRoot)\System32\drivers\etc\hosts"
                Value = "`r`n127.0.0.1  $domain"
            }
            Add-Content @params -WhatIf:$WhatIfPreference

            $mobileServer = Get-MobileServerInfo
            $url = "https://$($domain):$($mobileServer.HttpsPort)"
            if ($PSCmdlet.ShouldProcess("Open web browser to $url")) {
                Write-Output "Finished! Opening a web browser to $url"
                Start-Process $url
            }
        } catch {
            throw
        }
    }

    <#
    .SYNOPSIS
        Uses Posh-ACME to request a Let's Encrypt certificate and configure Mobile Server to use it

    .DESCRIPTION
        Uses Posh-ACME to request a Let's Encrypt certificate and configure Mobile Server to use it, then
        creates a Scheduled Task to run daily, and execute a renewal script which will handle certificate
        renewal when the certificate becomes eligible for renewal - typically 60 days after issue.

        When the certificate is renewed, it will be installed into the Windows certificate store and the
        old certificate will be removed from the certificate store. The Milestone XProtect Mobile Server
        service will be restarted so that it automatically uses the renewed certificates going forward.

    .PARAMETER Domain
        The domain for which you will request a Let's Encrypt certificate. See Get-Help New-PACertificate for more info.

    .PARAMETER Contact
        The email address associated with this domain for the purpose of renewal notifications. See Get-Help New-PACertificate for more info.

    .PARAMETER DnsPlugin
        The DnsPlugin to use for handling DNS challenges. See Get-Help New-PACertificate for more info.

    .PARAMETER PluginArgs
        A hashtable with the necessary parameters for the chosen DnsPlugin. See Get-Help New-PACertificate for more info.

    .PARAMETER ScriptDirectory
        The path where the renew-certificate.ps1 script will be saved, and the log.txt file will be written to.

        A scheduled task named Posh-ACME Certificate Renewal will be created to run the renew-certificate.ps1 script daily,
        and this script will append information to log.txt in the same path.

    .EXAMPLE
        $InstallParams = @{
            Domain = test.example.com
            Contact = admin@example.com
            DnsPlugin = Dynu
            PluginArgs = @{DynuClientID='xxxx';DynuSecret='xxxx'}
            ScriptDirectory = "C:\scripts"
        }
        Install-CertificateAutomation @InstallParams

        Requests a Let's Encrypt certificate for test.example.com, uses Dynu DNS to handle the ACME-protocol DNS challenge,
        binds the certificate to the Mobile Server's HTTPS port using 'netsh http add|update sslcert', restarts the Mobile
        Server service, creates a .PS1 certificate renewal script in C:\scripts\ and a scheduled task to call this script
        daily at 2AM, logging the result to C:\scripts\log.txt.
    #>
}