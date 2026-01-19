####################################################################################################
<#
.SYNOPSIS
    This function deploys a Local Group.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Invoke-DeployLocalGroup -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.3
    Author          : Imraan Iotana
    Creation Date   : June 2025
    Last Update     : June 2025
#>
####################################################################################################

function Invoke-DeployLocalGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $DeploymentObject,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Install','Uninstall','Reinstall')]
        [System.String]
        $Action = 'Install'
    )
    
    begin {

        ####################################################################################################

        # Create the main object
        [PSCustomObject]$Local:MainObject = @{
            # Function
            FunctionName            = [System.String]$MyInvocation.MyCommand
            FunctionArguments       = [System.String]$PSBoundParameters.GetEnumerator()
            ParameterSetName        = [System.String]$PSCmdlet.ParameterSetName
            FunctionCircumFix       = [System.String]'Function: [{0}] ParameterSetName: [{1}] Arguments: {2}'
            # Handlers
            ValidationIsSuccessful  = [System.Boolean]$true
            # Input
            DeploymentObject        = $DeploymentObject
            Action                  = $Action
            # Output
            DeploymentIsSuccesful   = [System.Boolean]$true
        }

        ####################################################################################################

        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Add the function details
            Add-Member -InputObject $this -NotePropertyName FunctionDetails -NotePropertyValue ($this.FunctionCircumFix -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments)
            # Write the Begin message
            Write-Verbose ('+++ BEGIN {0}' -f $this.FunctionDetails)
            # Validate the input
            $this.ValidateInput()
        }
    
        # Add the End method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name End -Value {
            # Write the End message
            Write-Verbose ('___ END {0}' -f $this.FunctionDetails)
        }

        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # If the validation was not successful then return
            if (-Not($this.ValidationIsSuccessful)) { Return }
            # Switch on the Action
            [PSCustomObject]$DeploymentObject = $this.DeploymentObject
            switch ($this.Action) {
                'Install'   { $this.InstallProcess($DeploymentObject) }
                'Uninstall' { $this.UninstallProcess($DeploymentObject) }
                'Reinstall' { $this.UninstallProcess($DeploymentObject) ; $this.InstallProcess($DeploymentObject) }
            }
        }

        ####################################################################################################
    
        # Add the ValidateInput method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInput -Value {
            # Validate the string
            if (Test-Object -IsEmpty $this.DeploymentObject.LocalGroupName) {
                Write-Host 'Invoke-DeployLocalGroup - ValidateInput: The LocalGroupName string is empty.' -ForegroundColor Red
                $this.ValidationIsSuccessful = $false
            }
            # Switch on the boolean
            switch ($this.ValidationIsSuccessful) {
                $true   { Write-Host ('{0}: The validation was successful. The Process method will now start.' -f $this.FunctionName) }
                $false  { Write-Host ('{0}: The validation was NOT successful. The Process method will not start.' -f $this.FunctionName) -ForegroundColor Red }
            }
        }

        ####################################################################################################
    
        # Add the InstallProcess method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name InstallProcess -Value { param([PSCustomObject]$DeploymentObject)
            # If the boolean is false, the return
            if ($DeploymentObject.CreateDuringInstall -eq $false) {
                Write-Host ('The CreateDuringInstall boolean has been set to false. No action has been taken. ({0})' -f $DeploymentObject.LocalGroupName)
                Return
            }
            # Create the LocalGroup
            if (-Not($this.TestLocalGroupExists($DeploymentObject.LocalGroupName))) { $this.CreateLocalGroup($DeploymentObject) }
            # Make the LocalGroup member of the Parent Group
            $this.AddLocalGroupToParent($DeploymentObject)
            # Add the member to the LocalGroup
            $this.AddMemberToLocalGroup($DeploymentObject)
        }
    
        # Add the UninstallProcess method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name UninstallProcess -Value { param([PSCustomObject]$DeploymentObject)
            # If the boolean is false, the return
            if ($DeploymentObject.RemoveDuringUninstall -eq $false) {
                Write-Host ('The RemoveDuringUninstall boolean has been set to false. No action has been taken. ({0})' -f $DeploymentObject.LocalGroupName)
                Return
            }
            # Remove the LocalGroup
            if ($this.TestLocalGroupExists($DeploymentObject.LocalGroupName)) { $this.RemoveLocalGroup($DeploymentObject) }
        }

        ####################################################################################################
        # SUPPORTING METHODS

        # Add the TestLocalGroupExists method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestLocalGroupExists -Value { param([System.String]$LocalGroupName)
            # Test the LocalGroup
            Write-Host ('Testing if the Local Group exists... ({0})' -f $LocalGroupName)
            [Microsoft.PowerShell.Commands.LocalPrincipal]$LocalGroupExists = Get-LocalGroup -Name $LocalGroupName -ErrorAction SilentlyContinue
            if ($LocalGroupExists) {
                Write-Host ('The Local Group exists. ({0})' -f $LocalGroupName) ; $true
            } else {
                Write-Host ('The Local Group does NOT exist. ({0})' -f $LocalGroupName) ; $false
            }
        }

        # Add the CreateLocalGroup method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name CreateLocalGroup -Value { param([PSCustomObject]$DeploymentObject)
            try {
                # Create the LocalGroup
                Write-Host ('Creating the Local Group... ({0})' -f $DeploymentObject.LocalGroupName)
                New-LocalGroup -Name $DeploymentObject.LocalGroupName -Description $DeploymentObject.Description
            }
            catch {
                Write-FullError
            }
        }

        # Add the RemoveLocalGroup method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name RemoveLocalGroup -Value { param([PSCustomObject]$DeploymentObject)
            try {
                # Remove the LocalGroup
                Write-Host ('Removing the Local Group... ({0})' -f $DeploymentObject.LocalGroupName)
                Remove-LocalGroup -Name $DeploymentObject.LocalGroupName
            }
            catch {
                Write-FullError
            }
        }

        # Add the AddLocalGroupToParent method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name AddLocalGroupToParent -Value { param([PSCustomObject]$DeploymentObject)
            # Set the properties
            [System.String]$LocalGroupName      = $DeploymentObject.LocalGroupName
            [System.String[]]$ParentGroupNames  = $DeploymentObject.MakeMemberOf
            # Make the LocalGroup member of the Parent Group
            if ($ParentGroupNames.Count -eq 0) {
                Write-Host ('The MakeMemberOf/ParentGroupNames array is empty. The Local Group has NOT been made a member of another group. ({0})' -f$LocalGroupName)
            } else {
                foreach ($ParentGroupName in $ParentGroupNames) {
                    try {
                        Add-LocalGroupMember -Group $ParentGroupName -Member $LocalGroupName
                        Write-Host ('The Local Group ({0}) has been made a member of the Parent Group ({1}).' -f$LocalGroupName,$ParentGroupName)
                    }
                    catch {
                        Write-FullError -Message ('AddLocalGroupToParent: An error occured while adding the Local Group ({0}) to the Parent Group ({1}).' -f$LocalGroupName,$ParentGroupName)
                    }
                }
            }
        }

        # Add the AddMemberToLocalGroup method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name AddMemberToLocalGroup -Value { param([PSCustomObject]$DeploymentObject)
            # Set the properties
            [System.String]$LocalGroupName  = $DeploymentObject.LocalGroupName
            [System.String[]]$MembersToAdd    = $DeploymentObject.AddMemberUserOrGroup
            # Make the MemberToAdd member of the Local Group
            if ($MembersToAdd.Count -eq 0) {
                Write-Host ('The AddMemberUserOrGroup/MembersToAdd array is empty. No member has been added to the Local Group. ({0})' -f$LocalGroupName)
            } else {
                foreach ($MemberToAdd in $MembersToAdd) {
                    try {
                        Add-LocalGroupMember -Group $LocalGroupName -Member $MemberToAdd
                        Write-Host ('The member ({0}) has been added to the Local Group ({1}).' -f$MemberToAdd,$LocalGroupName)
                    }
                    catch {
                        Write-FullError -Message ('AddMemberToLocalGroup: An error occured while adding the member ({0}) to the Local Group ({1}).' -f$MemberToAdd,$LocalGroupName)
                    }
                }
            }
        }

        ####################################################################################################

        $Local:MainObject.Begin()
    }
    
    process {
        $Local:MainObject.Process()
    }

    end {
        $Local:MainObject.End()
        # Return the output
        $Local:MainObject.DeploymentIsSuccesful
    }
}

