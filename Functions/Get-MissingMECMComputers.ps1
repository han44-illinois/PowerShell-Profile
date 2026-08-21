function Get-MissingMECMComputers{

    <#
    .SYNOPSIS
        Compares MECM computers with AD computers to see what might have fallen out due to being offline for extended periods of time.

    .DESCRIPTION
        Compares MECM computers with AD computers to see what might have fallen out due to being offline for extended periods of time.

    .EXAMPLE
        PS> Get-MissingMECMComputers

        Runs this command

    .NOTES
        General notes
    #>

    [CmdletBinding()]

    param(
        [string] $MECMCollection = "UIUC-ENGR-Instructional All Systems",
        [string] $ADSearchBase = "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu",
        [string] $ADExclusionRegex = "NoInheritance|SPARE|TEST"
    )

    BEGIN{
        Prep-MECM
    }

    PROCESS{
        $MECMComps = Get-CMCollectionMember -CollectionName $MECMCollection | Select-Object -ExpandProperty Name | Sort-Object
        $ADComps = Get-ADComputer -Filter * -SearchBase $ADSearchBase | Where-Object {$_.DistinguishedName -notmatch $ADExclusionRegex} | Select-Object -ExpandProperty Name | Sort-Object
        $Result = Compare-Object -ReferenceObject $ADComps -DifferenceObject $MECMComps | Where-Object {$_.SideIndicator -eq '<='} | Select-Object -ExpandProperty InputObject
    }

    END{
        Write-Host "Missing computers in MECM:"
        $Result
    }
}