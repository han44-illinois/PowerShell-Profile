function Get-BIOSFromLab{

    <#
    .SYNOPSIS
        Queries the Win32_BIOS for an entire computer lab.

    .DESCRIPTION
        A convenience function to query the Win32_BIOS for an entire computer lab.

    .PARAMETER comps
        Computer Lab name with wildcard e.g. eh-110a-*

    .EXAMPLE
        PS>

        Example of how to use this cmdlet

    .EXAMPLE
        PS>

        Another example of how to use this cmdlet

    .INPUTS
        Inputs to this cmdlet (if any)

    .OUTPUTS
        Output from this cmdlet (if any)

    .LINK
        Any related function or website

    .NOTES
        General notes
    #>

    [CmdletBinding()]

    param(
        [Parameter()]
        [string] $Comps
    )
    

    BEGIN{}

    PROCESS{
        Get-ADComputer -Filter {name -like $comps} -SearchBase "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" | 
            ForEach-Object -ThrottleLimit 20 -Parallel {
                if(Test-Connection $_.Name -IPv4 -Quiet -Count 1){ 
                    Get-CimInstance -ClassName Win32_BIOS -ComputerName $_.Name | Select-Object PSComputerName,SMBIOSBIOSVersion 
                }else{
                    Write-Host "$($_.Name) did not respond" -ForegroundColor Red
                }
            } | 
                Sort-Object -Property PSComputerName
        
    }

    END{}
}