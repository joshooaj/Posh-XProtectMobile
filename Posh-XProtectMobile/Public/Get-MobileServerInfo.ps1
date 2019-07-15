function Get-MobileServerInfo {
    [CmdletBinding()]
    param ( )
    process {
        $mobServerPath = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Milestone\XProtect Mobile Server' -Name INSTALLATIONFOLDER
        [Xml]$doc = Get-Content "$mobServerPath.config"

        $xpath = "/configuration/ManagementServer/Address/add[@key='Ip']"
        $msIp = $doc.SelectSingleNode($xpath).Attributes['value'].Value
        $xpath = "/configuration/ManagementServer/Address/add[@key='Port']"
        $msPort = $doc.SelectSingleNode($xpath).Attributes['value'].Value

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
            Version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($mobServerPath).FileVersion;
            ExePath = $mobServerPath;
            ConfigPath = "$mobServerPath.config";
            ManagementServerIp = $msIp;
            ManagementServerPort = $msPort;
            HttpIp = $httpIp;
            HttpPort = $httpPort;
            HttpsIp = $httpsIp;
            HttpsPort = $httpsPort;
            CertHash = Get-MobileServerSslCertThumbprint -IPPort "$($httpsIp):$($httpsPort)" -ErrorAction SilentlyContinue
        }
        $info
    }

    <#
    .SYNOPSIS
        Gets details about the local Milestone XProtect Mobile Server installation.

    .DESCRIPTION
        Gets details about the local Milestone XProtect Mobile Server installation.
        Properties include
        - Version
        - ExePath
        - ConfigPath
        - ManagementServerIp
        - ManagementServerPort
        - HttpIp
        - HttpPort
        - HttpsIp
        - HttpsPort
        - CertHash
    #>
}
