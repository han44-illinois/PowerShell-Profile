function Check-LatestModifiedDate {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Path
    )

    $Folder = Get-Item -Path $Path
    if($Folder.Attributes -notlike "*Directory*"){
        throw "$Folder is not a folder. Try another path!"
    }

    $NewestDateStamp = Get-Date -UnixTimeSeconds 0

    $Files = Get-ChildItem -Path $Path
    foreach($File in $Files){
        if($File.Attributes -notlike "*Directory*"){
            Write-Verbose "Processing $($File.FullName)"
            Write-Verbose "$($File.Name) was last modified $($File.LastWriteTime)"
            if($File.Name -ne "Thumbs.db"){
                if($File.LastWriteTime -gt $NewestDateStamp){
                    Write-Verbose "New latest modified file found!"
                    $NewestDateStamp = $File.LastWriteTime
                    $NewestFile = $File.FullName
                }
            }
        }
    }

    $Output = [PSCustomObject]@{
        ClassDir = $Folder.Name
        NewestFile = $NewestFile
        NewestDateStamp = $NewestDateStamp
    }
    $Output
}

#$ClassDirs = Get-ChildItem -Path "\\ad.uillinois.edu\engr-ews\classes" -Directory
#$Output = $ClassDirs | ForEach-Object {
#    Check-LatestModifiedDate -Path $_.FullName
#}