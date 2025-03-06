function Get-VLANForIP{

    <#
    .SYNOPSIS
        Walks back IP's until the result is a gateway, then returns the gateway

    .DESCRIPTION
        Walks back IP's until the result is a gateway, then returns the gateway

    .PARAMETER IPv4Address
        Basic string. Please put in a valid IP because I could not be bothered sanitizing inputs.

    .EXAMPLE
        PS> Get-VLANForIP -IPv4Address 172.21.235.185 -Verbose

        Walks back IP's from 172.21.235.185 until it reaches a gateway with Verbose output, so you know where it is in terms of progress.

    .OUTPUTS
        The gateway e.g. 0013-apn-net.gw.uiuc.edu

    .NOTES
        As of this current writing, IP decrements is only supported in the latter two octets. It'd probably be faster to use other means to figure out your vlan if you needed to walk back further than that anyway, so I didn't bother building logic in for that.
    #>

    [CmdletBinding()]

    param(
        [string] $IPv4Address
    )

    BEGIN{
        $Resolved = $false
        function Decrement-IPv4 ($IP){
            [int]$oct1 ,[int]$oct2 ,[int]$oct3 ,[int]$oct4 = $IP.Split(".")
            if($oct4 -eq 0){
                $oct4 = 256
                $oct3 = $oct3 - 1
            }
            $IP = "$oct1.$oct2.$oct3.$($oct4 - 1)"
            $IP
        }
        Write-Verbose "Starting check with $IPv4Address"
    }

    PROCESS{
        while(-not $Resolved){
            $Result = Resolve-DnsName -Name $IPv4Address -ErrorAction SilentlyContinue
            if($Result){
                if($Result.NameHost -match ".gw.uiuc.edu") {
                    Write-Verbose "Match was found on $IPv4Address"
                    $Resolved = $true
                    $Result.NameHost
                }
            } 
            # else
            $IPv4Address = Decrement-IPv4 -IP $IPv4Address
            Write-Verbose "Match was not found. Checking $IPv4Address"
        }
    }

    END{
        Write-Host "Check for building code: https://fs.illinois.edu/building-list-by-building-number/"
    }
}