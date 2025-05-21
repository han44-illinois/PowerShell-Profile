function Build-RefreshImportCSVs{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $InputFile,
        [Parameter(Mandatory)]
        [string]
        $OutputPath
    )

        # Columns from the CSV because this seems to change every year.
        $ColumnLab = "Actual Lab"
        $ColumnName = "Actual Hostname"
        $ColumnMac = 'LOM MAC (10GB NIC)'
        $ColumnOS = 'Actual OS/Image'

        # Spare Lab. This value should be whatever marks our spares, since we don't care to create import sheets for those.
        $SpareLab = "EWS-FY25"
    
        if([IO.Path]::GetExtension($InputFile) -ne ".csv"){
            throw "This function requires a .csv input!"
        }
    
        if(-not (Test-Path $OutputPath)){
            New-Item -Path $OutputPath -ItemType Directory
        }
    
        if(-not (Test-Path "$OutputPath\MECM")){
            New-Item -Path "$OutputPath\MECM" -ItemType Directory
        }

        if(-not (Test-Path "$OutputPath\Satellite")){
            New-Item -Path "$OutputPath\Satellite" -ItemType Directory
        }
    
        if(-not (Test-Path "$OutputPath\IPAM")){
            New-Item -Path "$OutputPath\IPAM" -ItemType Directory
        }
    
        $Refresh = Get-Content $InputFile | ConvertFrom-Csv | Where-Object {$_.$ColumnLab -notlike $SpareLab}
        $Labs = $Refresh.$ColumnLab | Sort-Object -Unique
        $LabsToCheck = New-Object -TypeName System.Collections.ArrayList
        $IPsToCheck = New-Object -TypeName System.Collections.ArrayList
    
        $Labs | ForEach-Object {
            $CurrentLab = $_
            $MECMcsv = New-Object -TypeName System.Collections.ArrayList
            $IPAMcsv = New-Object -TypeName System.Collections.ArrayList
            $SatelliteTXT = New-Object -TypeName System.Collections.ArrayList

            $SatelliteTXT.Add('#!/bin/bash') | Out-Null
    
            $Refresh | ForEach-Object {
                if($_.Lab -eq $CurrentLab){
                    $ComputerName = $_.$ColumnName
                    $MACAddress = $_.$ColumnMac -split '(..)' -ne '' -join ":"
                    $OS = $_.$ColumnOS

                    $Hostname = ($ComputerName + ".ews.illinois.edu") -replace ".ews.illinois.edu.ews.illinois.edu",".ews.illinois.edu"

                    if($OS -eq "Windows"){
                        $MECMResult = [PSCustomObject]@{
                            ComputerName    = $ComputerName
                            MACAddress      = $MACAddress
                        }
                        $MECMcsv.Add($MECMResult) | Out-Null
                    }

                    if($OS -eq "RHEL"){
                        $SatelliteResult = "hammer host create --name $ComputerName --interface mac=$MACAddress --hostgroup=rhel-9-serv-x86_64 --pxe-loader 'Grub2 UEFI' --parameters part_device=/dev/nvme0n1 --organization='GCoE' --location='Instructional' --subnet=default"
                        $SatelliteTXT.Add($SatelliteResult) | Out-Null
                    }

                    if($OS -eq "Ubuntu"){
                        $SatelliteResult = "hammer host create --name $ComputerName --interface mac=$MACAddress --hostgroup=ubuntu-24-eli-x86_64 --pxe-loader 'Grub2 UEFI' --parameters part_device=/dev/nvme0n1 --organization='GCoE' --location='Instructional' --subnet=default"
                        $SatelliteTXT.Add($SatelliteResult) | Out-Null
                    }
    
                    try{
                        $IPAddress = ([System.Net.Dns]::GetHostAddresses($Hostname)).IPAddressToString
                        if($IPAddress.Count -ge 2){
                            $IPsToCheck.Add($Hostname) | Out-Null
                            $IPAddress = $IPAddress[0]
                        }
                    } catch {
                        $IPAddress = ""
                        $LabsToCheck.Add($CurrentLab) | Out-Null
                    }
                    
                    if($OS -eq "Windows"){
                        $IPAMResult = [PSCustomObject]@{
                            "header-hostaddress"    = "hostaddress"
                            "address*"              = $IPAddress
                            "parent*"               = $Hostname
                            "boot_file"             = ""
                            "configure_for_dhcp"    = "TRUE"
                            "mac_address"           = $MACAddress
                            "next_server"           = ""
                        }
                    }
                    if(($OS -eq "RHEL") -or ($OS -eq "Ubuntu")){
                        $IPAMResult = [PSCustomObject]@{
                            "header-hostaddress"    = "hostaddress"
                            "address*"              = $IPAddress
                            "parent*"               = $Hostname
                            "boot_file"             = "grub2/grubx64.efi"
                            "configure_for_dhcp"    = "TRUE"
                            "mac_address"           = $MACAddress
                            "next_server"           = "satellite.engrit.illinois.edu"
                        }
                    }
                    $IPAMcsv.Add($IPAMResult) | Out-Null
                }
            }
            if($OS -eq "Windows")                           {$MECMcsv | ConvertTo-Csv -NoHeader  | Out-File "$OutputPath\MECM\$CurrentLab-MECM.csv"}
            if(($OS -eq "RHEL") -or ($OS -eq "Ubuntu"))     {$SatelliteTXT | Out-File "$OutputPath\Satellite\$CurrentLab-Satellite.txt"}
            $IPAMcsv | ConvertTo-Csv            | Out-File "$OutputPath\IPAM\$CurrentLab-IPAM.csv"
            Write-Host "Processed $CurrentLab"
        }
    
        Write-Host "Finished processing."
    
        if($LabsToCheck){
            $LabsToCheck = $LabsToCheck | Sort-Object -Unique
            Write-Host "Some labs seem to be missing host records in IPAM. Please check the IP Address fields for the IPAM import csvs for the following labs:"
            Write-Host $LabsToCheck
        }
        if($IPsToCheck){
            $IPsToCheck = $IPsToCheck | Sort-Object -Unique
            Write-Host "Some computers seem to have multiple IP's. Please check the records for the following host records:"
            Write-Host $IPsToCheck
        }
    }