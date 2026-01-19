####################################################################################################
<#
.SYNOPSIS
    This function deploys the objects.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    -
.INPUTS
    This function has no input parameters.
.OUTPUTS
    This function returns no output.
.NOTES
    Version         : 3.0
    Author          : Imraan Noormohamed
    Creation Date   : July 2023
    Last Updated    : July 2023
#>
####################################################################################################

function Deploy-Objects {
    [CmdletBinding()]
    param (
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Function
        [System.String]$PreFix          = "[$($MyInvocation.MyCommand)]:"

        # Create the main object
        [PSCustomObject]$Local:MainObject = @{
            FunctionHandler             = [FunctionHandler]::New([System.String]$MyInvocation.MyCommand,[System.String]$PSBoundParameters.GetEnumerator(),[System.String]$PSCmdlet.ParameterSetName)

            GlobalDeploymentObject      = [PSCustomObject]$Global:DeploymentObject
            ObjectCounter               = [System.Int32]0

            TotalDeploymentResultArray  = [System.Boolean[]]@()

            FinalStatusForRegistry      = [System.Collections.Hashtable]@{
                TotalInstallSuccess     = 'INSTALL_SUCCESS'
                TotalInstallFail        = 'INSTALL_FAIL'
                TotalUninstallSuccess   = 'UNINSTALL_SUCCESS'
                TotalUninstallFail      = 'UNINSTALL_FAIL'
                TotalReinstallFail      = 'REINSTALL_FAIL'
                TotalDeploymentAborted  = 'DEPLOYMENT_ABORTED'
            }
        }

        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Write the Begin message
            $this.FunctionHandler.WriteBeginMessage()
            # Prepare the Deployment
            Start-DeploymentProcess
        }

        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # Get the action (Install, Uninstall or Reinstall)
            [System.String]$Action = $this.GlobalDeploymentObject.Action
            # For each DeploymentObject
            foreach ($DeploymentObject in $this.GlobalDeploymentObject.DeploymentObjects) {
                # Up the counter
                $this.ObjectCounter++
                # Get the DeploymentObject Type
                [System.String]$DeploymentObjectType = $DeploymentObject.Type
                # Write the message
                Write-Line -Type DoubleSeperation
                Write-Line "$PreFix Deploying object ($($this.ObjectCounter)) of ($($this.GlobalDeploymentObject.DeploymentObjects.Count))... ($DeploymentObjectType - $Action)" -Type Special
                # Deploy the object
                [System.Boolean]$ObjectDeploymentIsSuccesful = switch ($DeploymentObjectType) {
                    # GENERAL INSTALLATIONS
                    'DEPLOYMSI'                 { Start-MSIDeployment               -DeploymentObject $DeploymentObject -Action $Action } # 5.5.1
                    'REMOVEMSI'                 { Start-MSIRemoval                  -DeploymentObject $DeploymentObject -Action $Action } # 5.6.2
                    'DEPLOYEXECUTABLE'          { Start-ExecutableDeployment        -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DEPLOYISSSETUP'            { Start-ISSDeployment               -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DEPLOYINNOSETUP'           { Start-INNODeployment              -DeploymentObject $DeploymentObject -Action $Action } # 5.5.2
                    # FILES AND FOLDERS
                    'DEPLOYBASICFOLDERCOPY'     { Start-BasicFolderDeployment       -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DEPLOYCOMPRESSEDFOLDER'    { Start-CompressedFolderDeployment  -DeploymentObject $DeploymentObject -Action $Action } # 5.5.2
                    'DEPLOYBASICFILECOPY'       { Start-BasicFileDeployment         -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DEPLOYSYSTEMFILECOPY'      { Start-SystemFileCopyDeployment    -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DEPLOYPOWERSHELLAPP'       { Start-PowerShellAppDeployment     -DeploymentObject $DeploymentObject -Action $Action } # 5.5.2
                    # MS OFFICE
                    'DEPLOYMSOFFICE'            { Start-MSOfficeDeployment          -DeploymentObject $DeploymentObject -Action $Action } # 5.5.2
                    'DEPLOYTRUSTEDLOCATION'     { Start-TrustedLocationDeployment   -DeploymentObject $DeploymentObject -Action $Action } # 5.5.2
                    # SQL
                    'DEPLOYSQLEXPRESS'          { Start-SQLExpressDeployment        -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DEPLOYSQLSCRIPT'           { Start-SQLScriptDeployment         -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    # LOCAL GROUP
                    'DEPLOYLOCALGROUP'          { Start-LocalGroupDeployment        -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'REMOVELOCALGROUPMEMBER'    { Start-RemoveUserFromLocalGroup    -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    # RUN SCRIPTS
                    'RUNCMDFILE'                { Start-CMDScriptDeployment         -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    # OTHER
                    'DEPLOYREGFILE'             { Start-REGFileDeployment           -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DEPLOYWINDOWSPACKAGE'      { Start-WindowsPackageDeployment    -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DISABLESCHEDULEDTASK'      { Start-DisableScheduledTask        -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DEPLOYFONT'                { Deploy-Font                       -DeploymentObject $DeploymentObject -Action $Action } # 5.5.1
                    'DEPLOYUSERPROFILEFOLDER'   { Deploy-UserProfileFolder          -DeploymentObject $DeploymentObject -Action $Action } # 5.5.1
                    'DEPLOYACTIVESETUP'         { Deploy-ActiveSetup                -DeploymentObject $DeploymentObject -Action $Action } # 5.5.1
                    'DEPLOYSYSTEMPATH'          { Start-SystemPathDeployment        -DeploymentObject $DeploymentObject -Action $Action } # 5.5.1
                    'DEPLOYSHORTCUT'            { Start-ShortcutDeployment          -DeploymentObject $DeploymentObject -Action $Action } # 5.5.2
                    'REMOVESHORTCUT'            { Start-ShortcutRemoval             -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DEPLOYPAUSE'               { Start-PauseDeployment             -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DEPLOYPYTHONMODULE'        { Start-PythonModuleDeployment      -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3
                    'DEPLOYPROCESSSTOP'         { Start-ProcessStopDeployment       -DeploymentObject $DeploymentObject -Action $Action } # 5.5.3

                    # LEGACY
                    'MSIX'                      { Invoke-MSIXDeployment             -DeploymentObject $DeploymentObject -Action $Action } # 3.2
                    'RUNEXE'                    { Invoke-RunEXE                     -DeploymentObject $DeploymentObject -Action $Action } # 3.2
                    'RUNPS1SCRIPT'              { Invoke-StartPS1Script             -DeploymentObject $DeploymentObject -Action $Action } # 3.4
                    'INFDRIVER'                 { Invoke-INFDriverDeployment        -DeploymentObject $DeploymentObject -Action $Action }
                    'CERTIFICATE'               { Invoke-CertificateDeployment      -DeploymentObject $DeploymentObject -Action $Action } # 3.2
                    'DOTNET35'                  { Invoke-DotNet35Deployment         -DeploymentObject $DeploymentObject -Action $Action } # 3.2
                    'VSTO'                      { Invoke-VSTODeployment             -DeploymentObject $DeploymentObject -Action $Action } # 3.2
                    'STOPSERVICE'               { Invoke-StopService                -DeploymentObject $DeploymentObject -Action $Action } # 5.1
                    'DISABLESERVICE'            { Invoke-DisableService             -DeploymentObject $DeploymentObject -Action $Action } # 5.1
                    'ARPENTRY'                  { Invoke-ARPEntry                   -DeploymentObject $DeploymentObject -Action $Action }

                    Default                     { Write-Line "$PreFix The Deployment Object is not recognized: ($DeploymentObjectType)" -Type Fail ; $false }
                }
                # Add the result to the TotalDeploymentResultArray
                Write-Verbose "$PreFix Adding the Deployment Result to the TotalDeploymentResultArray... ($($ObjectDeploymentIsSuccesful.ToString()))"
                $this.TotalDeploymentResultArray += $ObjectDeploymentIsSuccesful
                # If the Object Deployment was succesful
                if ($ObjectDeploymentIsSuccesful) {
                    # Write the message
                    Write-Line "$PreFix The $Action-process of ($DeploymentObjectType) was successful." -Type Success
                }
                # If the Object Deployment was NOT succesful
                else {
                    # Write the message
                    Write-Line "$PreFix The $Action-process of ($DeploymentObjectType) was NOT successful." -Type Fail
                    # Set the result in the GlobalDeploymentObject (This must be done directly in the Global variable.)
                    $Global:DeploymentObject.DeploymentResult = switch ($Action) {
                        'Install'   { $this.FinalStatusForRegistry.TotalInstallFail }
                        'Uninstall' { $this.FinalStatusForRegistry.TotalUninstallFail }
                        'Reinstall' { $this.FinalStatusForRegistry.TotalReinstallFail }
                    }
                    # Abort or continue the deployment sequence, depending on the value of AbortWhenOneFails
                    if ($this.GlobalDeploymentObject.AbortWhenOneFails -eq $true) {
                        Write-Line "$PreFix The deployment of one object has failed. The Deployment Sequence will be aborted." -Type Fail
                        # Set the end result in the GlobalDeploymentObject
                        $this.GlobalDeploymentObject.DeploymentResult = $this.FinalStatusForRegistry.TotalDeploymentAborted
                        # Break the loop
                        Break
                    }
                }
            }
        }

        # Add the End method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name End -Value {
            # If all deployments are succesfull
            if (-Not($this.TotalDeploymentResultArray -contains $false)) {
                Write-Line -Type DoubleSeperation
                Write-Line "$PreFix All ($($this.GlobalDeploymentObject.DeploymentObjects.Count)) $($this.GlobalDeploymentObject.Action)-actions have been executed successfully." -Type Success
                # Set the result in the GlobalDeploymentObject (This must be done directly in the Global variable.)
                $Global:DeploymentObject.DeploymentResult = switch ($this.GlobalDeploymentObject.Action) {
                    'Install'   { $this.FinalStatusForRegistry.TotalInstallSuccess }
                    'Uninstall' { $this.FinalStatusForRegistry.TotalUninstallSuccess }
                    'Reinstall' { $this.FinalStatusForRegistry.TotalInstallSuccess }
                }
            } else {
                # Write the message
                Write-Line "$PreFix The Deployment Sequence was not successful." -Type Fail
            }
            # End the Deployment process
            Stop-DeploymentProcess
            # Update the WorkSpaceManagers
            #try { Update-WorkSpaceManagers }
            #catch { Write-FullError }
            # Write the End message
            $this.FunctionHandler.WriteEndMessage()
        }

        ####################################################################################################

        $Local:MainObject.Begin()
    }

    process {
        # Set the location to the current folder
        Set-Location $Global:DeploymentObject.Rootfolder
        # Perform the rest of the Process method
        $Local:MainObject.Process()
    }
    
    end {
        $Local:MainObject.End()
    }
}


