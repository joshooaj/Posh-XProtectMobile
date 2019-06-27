function Get-MobileServerSslCertThumbprint {
    [CmdletBinding()]
    param (
        [parameter()]
        [string]
        $IPPort
    )
    process {
        $netshOutput = [string](netsh.exe http show sslcert ipport=$IPPort)
        
        if (!$netshOutput.Contains('Certificate Hash')) {
            Write-Error "No SSL certificate binding found for $ipPort"
            return
        }
        
        if (!($netshOutput -match "Certificate Hash\s+:\s+(\w+)\s+")) {
            Write-Error "Certificate Hash not found for $ipPort"
            return
        }
        
        $Matches[1]
    }

    <#
    .SYNOPSIS
        Gets the certificate thumbprint from the sslcert binding information put by netsh http show sslcert ipport=$IPPort

    .DESCRIPTION
        Gets the certificate thumbprint from the sslcert binding information put by netsh http show sslcert ipport=$IPPort.
        Returns $null if no binding is present for the given ip:port value.

    .PARAMETER IPPort
        The ip:port string representing the binding to retrieve the thumbprint from.

    .EXAMPLE
        Get-MobileServerSslCertThumbprint 0.0.0.0:8082

        Gets the sslcert thumbprint for the binding found matching 0.0.0.0:8082 which is the default HTTPS IP and Port for 
        XProtect Mobile Server. The value '0.0.0.0' represents 'all interfaces' and 8082 is the default https port.
    #>
}