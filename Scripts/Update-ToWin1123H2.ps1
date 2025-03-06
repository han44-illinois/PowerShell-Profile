function Import-PSWindowsUpdate {
    if(-not (Get-Module PSWindowsUpdate)){
        $null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module PSWindowsUpdate
    }
}

function Update-ToWin1123H2{

    BEGIN{
        #Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
        Import-PSWindowsUpdate
    }

    PROCESS{
        if((Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber -lt 22631){
            Get-WindowsUpdate | Out-Null
            Install-WindowsUpdate -KBArticleID KB5039212 -AcceptAll -AutoReboot
        }else{
            Write-Host "$env:COMPUTERNAME is already on Win11 23H2 or newer"
        }
    }

    END{}
}
Update-ToWin1123H2