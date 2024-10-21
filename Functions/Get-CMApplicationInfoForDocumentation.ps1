function Get-CMApplicationInfoForDocumentation{

    <#
    .SYNOPSIS
        A function to quickly extract necessary information for an application packaged in MECM for documentation purposes

    .DESCRIPTION
        A function to quickly extract necessary information for an application packaged in MECM for documentation purposes

    .PARAMETER Name
        Name of the application

    .EXAMPLE
        PS> Get-CMApplicationInfoForDocumentation -Name "UIUC-ENGR-Tera Term 5.3"

        This gets the application info from Tera Term 5.3

    .INPUTS
        Application Name.

    .OUTPUTS
        Outputs are to the clipboard with the Install String, Uninstall String, and Detection method respectively.
    #>

    [CmdletBinding()]

    param(
        [Parameter()]
        [String] $Name
    )

    BEGIN{
        $mypwd = $pwd
        Prep-MECM
    }

    PROCESS{
        $Application = Get-CMApplication -Name $Name
        $SDMPackageXML = [xml]$Application.SDMPackageXML

        $InstallerXML = [xml]$SDMPackageXML.AppMgmtDigest.DeploymentType.Installer.InstallAction.Args.OuterXml
        $InstallDirectory = ($InstallerXML.Args.Arg[1].'#text' + "\") -replace "\\","\"
        if($InstallDirectory.StartsWith('\')){
            $InstallDirectory = $InstallDirectory.TrimStart('\')
        }
        $InstallCommand = $InstallerXML.Args.Arg[0].'#text'
        $Install = '`' + $InstallDirectory + $InstallCommand + '`'

        $UninstallerXML = [xml]$SDMPackageXML.AppMgmtDigest.DeploymentType.Installer.UninstallAction.Args.OuterXml
        $UninstallDirectory = ($UninstallerXML.Args.Arg[1].'#text' + "\") -replace "\\","\"
        if($UninstallDirectory.StartsWith('\')){
            $UninstallDirectory = $UninstallDirectory.TrimStart('\')
        }
        $UninstallCommand = $UninstallerXML.Args.Arg[0].'#text'
        $Uninstall = '`' + $UninstallDirectory + $UninstallCommand + '`'

        $DetectionXML = [xml]$SDMPackageXML.AppMgmtDigest.DeploymentType.Installer.DetectAction.Args.Arg[1].'#text'
        
        # switch for detection method type to catch non-registry detection methods later
        # $DetectionType = 
        # switch $DetectionType {}
        # Registry {
        $Hive = $DetectionXML.EnhancedDetectionMethod.Settings.SimpleSetting.RegistryDiscoverySource.Hive
        $Key = $DetectionXML.EnhancedDetectionMethod.Settings.SimpleSetting.RegistryDiscoverySource.Key
        $Value = $DetectionXML.EnhancedDetectionMethod.Settings.SimpleSetting.RegistryDiscoverySource.ValueName

        $Operator = $DetectionXML.EnhancedDetectionMethod.Rule.Expression.Operator
        switch ($Operator) {
            # Add more cases here
            "GreaterEquals" {$OperatorChar = '>='}
            "Equals"        {$OperatorChar = '='}
        }

        $DetectionVersion = $DetectionXML.EnhancedDetectionMethod.Rule.Expression.Operands.ConstantValue.Value

        $DetectionMethod = '`Registry: ' + $Hive + ":\" + $Key + "\" + $Value + " " + $OperatorChar + " " + $DetectionVersion + '`'

        
    }

    END{
        Set-Clipboard $Install
        Read-Host -Prompt "Install string copied! Press any key for next copy"
        Set-Clipboard $Uninstall
        Read-Host -Prompt "Uninstall string copied! Press any key for next copy"
        Set-Clipboard $DetectionMethod
        Write-Host "Detection method copied!"

        Set-Location $mypwd
    }
}