function Invoke-CMCollectionUpdateForImaging {

    [CmdletBinding()]

    param(
        [Parameter(Mandatory)]
        [String] $ComputerName,
        [Int] $CheckingIntervalInSeconds = 120,
        [Int] $CheckLimitCount = 20,
        [Switch] $PassThru,
        [Switch] $Beep
    )

    BEGIN{    
        Write-Host "Starting at $(Get-Date -DisplayHint Time)"
        if($pwd.Path -ne "MP0:\"){
            Push-Location
            Prep-MECM
        }
        # "UIUC-ENGR-IS Deploy OSD TS (Win11 2025a, Available, no SC)"
        $ImagingCollection = "MP00344A"
    }

    PROCESS{

        $ComputerExists = $false
        $CheckCount = 0
        while ((-not $ComputerExists) -and ($CheckCount -le $CheckLimitCount)){
            $DeviceCheck = Get-CMDevice -Name $ComputerName -Resource
            if($DeviceCheck){
                $ComputerExists = $true
                Write-Host "Device discovered at $(Get-Date -DisplayHint Time)"
            }else{
                Write-Host "Device not found! Trying again in $CheckingIntervalInSeconds Seconds. $($CheckLimitCount - $CheckCount) attempts remaining."
                Start-Sleep -Seconds $CheckingIntervalInSeconds
                $CheckCount++
            }
            
        }

        $CollectionCheck = Get-CMCollectionMember -CollectionId $ImagingCollection -Name $ComputerName

        if(-not $CollectionCheck){
            # Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-Devices without MECM client"
            Invoke-CMDeviceCollectionUpdate -CollectionId MP001B10
            # Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-Instructional"
            Invoke-CMDeviceCollectionUpdate -CollectionId MP0003A8
            # Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-Instructional plus devices without MECM client"
            Invoke-CMDeviceCollectionUpdate -CollectionId MP001B56
            # Invoke-CMDeviceCollectionUpdate -Name $ImagingCollection
            Invoke-CMDeviceCollectionUpdate -CollectionId $ImagingCollection
            
            $ComputerExistsInCollection = $false
            $CheckCount = 0

            while((-not $ComputerExistsInCollection) -and ($CheckCount -le $CheckLimitCount)){
                $CollectionCheck = Get-CMCollectionMember -CollectionName $ImagingCollection -Name $ComputerName
                if($CollectionCheck){
                    $ComputerExistsInCollection = $true
                    Write-Host "Device in collection at $(Get-Date -DisplayHint Time)"
                    if($PassThru){
                        Write-Output $CollectionCheck
                    }
                }else{
                    Write-Host "Device not found in the imaging collection! Trying again in $CheckingIntervalInSeconds Seconds. $($CheckLimitCount - $CheckCount) attempts remaining."
                    $CheckCount++
                    Start-Sleep -Seconds $CheckingIntervalInSeconds
                }
            }
        }
    }

    END{
        if($Beep){
            [Console]::Beep(200,2000)
        }
        Pop-Location
    }
}