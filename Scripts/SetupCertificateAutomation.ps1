#Requires -RunAsAdministrator

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

Install-CertificateAutomation @InstallParams -Verbose