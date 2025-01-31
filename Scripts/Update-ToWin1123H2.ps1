function Import-PSWindowsUpdate {
    if(-not (Get-Module PSWindowsUpdate)){
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module PSWindowsUpdate
    }
}

function Update-ToWin1123H2{

    BEGIN{
        Import-PSWindowsUpdate
    }

    PROCESS{
        Install-WindowsUpdate -KBArticleID KB5037771 -AcceptAll -AutoReboot
    }

    END{}
}