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

        $CollectionCheck = Get-CMCollectionMember -CollectionName "UIUC-ENGR-IS Deploy OSD TS (Win11 2023c, Available, no SC)" -Name $ComputerName

        if(-not $CollectionCheck){
            Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-Devices without MECM client"
            Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-Instructional"
            Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-Instructional plus devices without MECM client"
            Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS Deploy OSD TS (Win11 2023c, Available, no SC)"
            Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS Deploy OSD TS (Win11 2025a, Available, no SC)"
            
            $ComputerExistsInCollection = $false
            $CheckCount = 0

            while((-not $ComputerExistsInCollection) -and ($CheckCount -le $CheckLimitCount)){
                $CollectionCheck = Get-CMCollectionMember -CollectionName "UIUC-ENGR-IS Deploy OSD TS (Win11 2025a, Available, no SC)" -Name $ComputerName
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