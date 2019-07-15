function ConvertTo-UnsecureString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [securestring]
        $SecureString
    )
    
    process {
        (New-Object pscredential ('none', $SecureString)).GetNetworkCredential().Password
    }

    <#
    .SYNOPSIS
        Converts a secure string back into an unsecure, plain text string.

    .DESCRIPTION
        Converts a secure string back into an unsecure, plain text string. Useful when you need to store a 
        sensitive value securely, but expose it temporarily in order to pass it to a command which does not 
        accept a [securestring] property.

    .PARAMETER Input
        A [securestring] value

    .EXAMPLE
        "Hello world!" | ConvertTo-SecureString -AsPlainText -Force | ConvertTo-UnsecureString

        Converts "Hello world!" to a [securestring] value, then back into a plain, unsecure string value.
    #>
}