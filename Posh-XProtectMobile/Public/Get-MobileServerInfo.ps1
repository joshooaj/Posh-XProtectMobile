function Get-MobileServerInfo {
    [CmdletBinding()]
    param ( )
    process {
        $mobServerPath = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Milestone\XProtect Mobile Server' -Name INSTALLATIONFOLDER
        [Xml]$doc = Get-Content "$mobServerPath.config"

        $xpath = "/configuration/HttpMetaChannel/Address/add[@key='Port']"
        $httpPort = [int]::Parse($doc.SelectSingleNode($xpath).Attributes['value'].Value)
        $xpath = "/configuration/HttpMetaChannel/Address/add[@key='Ip']"
        $httpIp = $doc.SelectSingleNode($xpath).Attributes['value'].Value
        if ($httpIp -eq '+') { $httpIp = '0.0.0.0'}

        $xpath = "/configuration/HttpSecureMetaChannel/Address/add[@key='Port']"
        $httpsPort = [int]::Parse($doc.SelectSingleNode($xpath).Attributes['value'].Value)
        $xpath = "/configuration/HttpSecureMetaChannel/Address/add[@key='Ip']"
        $httpsIp = $doc.SelectSingleNode($xpath).Attributes['value'].Value
        if ($httpsIp -eq '+') { $httpsIp = '0.0.0.0'}

        $info = [PSCustomObject]@{
            ExePath = $mobServerPath;
            ConfigPath = "$mobServerPath.config";
            HttpIp = $httpIp;
            HttpPort = $httpPort;
            HttpsIp = $httpsIp;
            HttpsPort = $httpsPort;
            CertHash = Get-MobileServerSslCertThumbprint -Port $httpsPort -ErrorAction SilentlyContinue
        }
        $info
    }
}
