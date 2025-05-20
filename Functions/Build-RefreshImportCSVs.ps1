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
    
        $Refresh = Get-Content $InputFile | ConvertFrom-Csv | Where-Object {$_.Lab -notlike "#VALUE!"}
        $Labs = $Refresh.Lab | Sort-Object -Unique
        $LabsToCheck = New-Object -TypeName System.Collections.ArrayList
        $IPsToCheck = New-Object -TypeName System.Collections.ArrayList
    
        $Labs | ForEach-Object {
            $CurrentLab = $_
            $MECMcsv = New-Object -TypeName System.Collections.ArrayList
            $IPAMcsv = New-Object -TypeName System.Collections.ArrayList
            $SatelliteTXT = New-Object -TypeName System.Collections.ArrayList
    
            $Refresh | ForEach-Object {
                if($_.Lab -eq $CurrentLab){
                    $ComputerName = $_.'Intended Hostname'
                    $MACAddress = $_.'LOM MAC (10GB NIC)' -split '(..)' -ne '' -join ":"
                    $OS = $_.'Intended OS/Image'

                    if($OS -eq "Windows"){
                        $MECMResult = [PSCustomObject]@{
                            ComputerName    = $ComputerName
                            MACAddress      = $MACAddress
                        }
                        $MECMcsv.Add($MECMResult) | Out-Null
                    }

                    if($OS -eq "Linux"){
                        $SatelliteResult = "hammer host create --name $ComputerName --interface mac=$MACAddress --hostgroup=rhel-9-serv-x86_64 --pxe-loader 'Grub2 UEFI' --parameters part_device=/dev/nvme0n1 --organization='GCoE' --location='Instructional' --subnet=default"
                        $SatelliteTXT.Add($SatelliteResult) | Out-Null
                    }
    
                    try{
                        $IPAddress = ([System.Net.Dns]::GetHostAddresses($ComputerName + ".ews.illinois.edu")).IPAddressToString
                        if($IPAddress.Count -ge 2){
                            $IPsToCheck.Add($ComputerName + ".ews.illinois.edu") | Out-Null
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
                            "parent*"               = $ComputerName + ".ews.illinois.edu"
                            "boot_file"             = ""
                            "configure_for_dhcp"    = "TRUE"
                            "mac_address"           = $MACAddress
                            "next_server"           = ""
                        }
                    }
                    if($OS -eq "Linux"){
                        $IPAMResult = [PSCustomObject]@{
                            "header-hostaddress"    = "hostaddress"
                            "address*"              = $IPAddress
                            "parent*"               = $ComputerName + ".ews.illinois.edu"
                            "boot_file"             = "grub2/grubx64.efi"
                            "configure_for_dhcp"    = "TRUE"
                            "mac_address"           = $MACAddress
                            "next_server"           = "satellite.engrit.illinois.edu"
                        }
                    }
                    $IPAMcsv.Add($IPAMResult) | Out-Null
                }
            }
            if($OS -eq "Windows")   {$MECMcsv | ConvertTo-Csv -NoHeader  | Out-File "$OutputPath\MECM\$CurrentLab-MECM.csv"}
            if($OS -eq "Linux")     {$SatelliteTXT | Out-File "$OutputPath\Satellite\$CurrentLab-Satellite.txt"}
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