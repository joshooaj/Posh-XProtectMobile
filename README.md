# Posh-LEXPMO
PowerShell module using Posh-ACME to automate Let's Encrypt certificate generation and renewal for Milestone XProtect Mobile Server

## Work in progress

This module is intended to use Posh-ACME to automate LetsEncrypt cert generation and then take care of the netsh commands to take the new cert hash and bind it to whatever the Mobile Server's HTTPS IP/Port are set to.

The default IP for http/https binding for Mobile Server is "+" which means "all interfaces". And the default HTTPS port is 8082. This module will read this information from VideoOS.MobileServer.Service.exe.config and use it to find/add/update/remove the certificate binding for that Ip:Port combination.

Currently a Get-MobileServerInfo cmdlet is used to return a PSCustomObject with the current installation path, http/s IP/Ports, and certificate hash aka thumbprint if available.

Set-MobileServerCertificate will take an X509Certificate (get-childitem cert:\LocalMachine\My) or a Thumbprint string, and add/update the binding via netsh, and if successful, restart the Mobile Server service to for the change to take effect immediately.

More work is needed to add other useful commands including the ability to remove the current certificate all together, and to merge Posh-ACME cert generation with the set-mobileservercertificate cmdlet, and perhaps a cmdlet to setup automation for this via Task Scheduler so that the user doesn't need to ever open Task Scheduler to setup automation themselves.
