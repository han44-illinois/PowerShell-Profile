function Get-LabMissingMonitors{

    <#
    .SYNOPSIS
        Check monitor counts on a lab. Returns computers that don't have the expected monitor count.

    .DESCRIPTION
        Check monitor counts on a lab. Returns computers that don't have the expected monitor count.

    .PARAMETER Lab
        Computer lab. e.g. "eh-406b1"

    .PARAMETER MonitorCount
        Expected monitor count. Default 2

    .PARAMETER SearchBase
        OU searchbase for Get-ADComputer. Default Instructional OU

    .EXAMPLE
        PS>

        Get-LabMissingMonitors -Lab eh-406b1 -MonitorCount 2

    .NOTES
        Requires modules ActiveDirectory and Get-WMIMonitorInfo
    #>

    [CmdletBinding()]

    param(
        [string] $Lab,
        [int] $MonitorCount = 2,
        [string] $SearchBase = "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu"
    )

    BEGIN{
        $Computers = Get-ADComputer -Filter "name -like `"$Lab*`"" -SearchBase $SearchBase
        [int]$ProgressCounter = 0
    }

    PROCESS{
        foreach($comp in $Computers){
            $ProgressParameters = @{
                Activity            = 'Checking Computers'
                Status              = $comp.name
                PercentComplete     = $(($ProgressCounter / $Computers.count) * 100)
            }
            Write-Progress @ProgressParameters
            if(Test-Connection -TargetName $comp.name -Count 1 -Quiet){
                if(((Get-WMIMonitorInfo -ComputerName $comp.name -ErrorAction SilentlyContinue).count) -ne 2){
                    $comp.name
                }
            }
            $ProgressCounter++
        }
        
    }

    END{}
}