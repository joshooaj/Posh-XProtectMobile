# Posh-XProtectMobile
PowerShell module intended to be used in a script to automate the certificate renewal process and ensure the Milestone XProtect Mobile Server is updated to use the new certificate.

## Work in progress

After testing the Posh-ACME module for automating Let's Encrypt certificate generation, I made this module to simplify the process of updating the Mobile Server to use a given certificate.

The default IP for http/https binding for Mobile Server is "+" which means "all interfaces". And the default HTTPS port is 8082. This module will read this information from VideoOS.MobileServer.Service.exe.config and use it to find/add/update/remove the certificate binding for that Ip:Port combination using netsh http add/delete/update sslcert.

Currently a Get-MobileServerInfo cmdlet is used to return a PSCustomObject with the current installation path, http/s IP/Ports, and certificate hash aka thumbprint if available.

Set-MobileServerCertificate will take an X509Certificate (get-childitem cert:\LocalMachine\My) or a Thumbprint string, and add/update the binding via netsh, and if successful, restart the Mobile Server service to for the change to take effect immediately.

Later on, this readme will be updated with a sample script which combines certificate generation/renewal using Posh-ACME with the Set-MobileServerCertificate cmdlet which can be saved as a *.ps1 file and setup in Windows as a daily scheduled task to ensure that when the certificate is up for renewal, it is automatically renewed and applied to the Mobile Server in a seamless fashion.