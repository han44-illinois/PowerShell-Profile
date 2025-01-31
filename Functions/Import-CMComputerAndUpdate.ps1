function Import-CMComputerAndUpdate {
    <#
    .SYNOPSIS
        Function to import a computer to MECM and subsequently update our imaging collections
    #>
    [CmdletBinding()]
    param (
        [string]
        $ComputerName,
        [string]
        $MACAddress
    )
    $myPWD = $pwd.Path

    Prep-MECM

    Import-CMComputerInformation -ComputerName $ComputerName -MacAddress $MACAddress
    Invoke-CMCollectionUpdateForImaging -ComputerName $ComputerName

    Set-Location $myPWD
}