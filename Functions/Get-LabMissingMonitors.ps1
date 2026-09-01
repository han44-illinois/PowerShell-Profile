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

    .PARAMETER IncludeInstructors
        Set this switch to include instructor systems. Default will exclude instructor stations.

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
        [string] $SearchBase = "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu",
        [switch] $IncludeInstructors
    )

    BEGIN{
        Write-Verbose "Running with parameters:"
        Write-Verbose "'Lab' = $Lab"
        Write-Verbose "'MonitorCount' = $MonitorCount"
        Write-Verbose "'SearchBase' = $SearchBase"
        Write-Verbose "'IncludeInstructors = $IncludeInstructors"
        $Computers = Get-ADComputer -Filter "name -like `"$Lab*`"" -SearchBase $SearchBase
        [int]$ProgressCounter = 0
    }

    PROCESS{
        if(-not ($IncludeInstructors)){
            Write-Verbose "Excluding instructor stations"
            $Computers = $Computers | Where-Object {$_.DistinguishedName -notlike "*Instructor PC*"}
        }
        foreach($comp in $Computers){
            Write-Verbose "Checking $($comp.name)"
            $ProgressParameters = @{
                Activity            = 'Checking Computers'
                Status              = $comp.name
                PercentComplete     = $(($ProgressCounter / $Computers.count) * 100)
            }
            Write-Progress @ProgressParameters
            if(Test-Connection -TargetName $comp.name -Count 1 -Quiet){
                $Monitors = Get-WMIMonitorInfo -ComputerName $comp.name -ErrorAction SilentlyContinue
                foreach($mon in $Monitors){
                    Write-Verbose $mon
                }
                if(($Monitors.count) -lt $MonitorCount){
                    Write-Verbose "$($comp.name) only had $($Monitors.count) monitors."
                    $comp.name
                } elseif(($Monitors.count) -gt $MonitorCount){
                    Write-Verbose "$($comp.name) had $($Monitors.count) monitors, more than the expected number!"
                }
            }else{
                Write-Verbose "$($comp.name) did not respond!"
            }
            $ProgressCounter++
        }
        
    }

    END{}
}