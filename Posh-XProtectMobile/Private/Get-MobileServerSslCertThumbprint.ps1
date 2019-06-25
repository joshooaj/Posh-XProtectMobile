function Get-MobileServerSslCertThumbprint {
    [CmdletBinding()]
    param ( 
        [int]
        $Port
    )
    process {
        $ipPort = "0.0.0.0:$Port"
        $netshOutput = [string](netsh.exe http show sslcert ipport=0.0.0.0:8082)
        
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
}