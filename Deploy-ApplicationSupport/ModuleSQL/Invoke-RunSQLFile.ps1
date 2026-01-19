####################################################################################################
<#
.SYNOPSIS
    This function runs an sql file.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Invoke-RunSQLFile -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.4.3
    Author          : Imraan Iotana
    Creation Date   : June 2025
    Last Update     : June 2025
#>
####################################################################################################

function Invoke-RunSQLFile {
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
            DeploymentIsSuccesful   = [System.Boolean]$null
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
            # Add the full path of the file to the main object
            [System.String]$SQLFileFullPath = Get-FileFullPath -FileName $this.DeploymentObject.SQLFileName
            [System.String]$SQLInstanceName = $this.DeploymentObject.SQLInstanceName
            # Switch on the Action
            switch ($this.Action) {
                'Install'   { $this.Install($SQLFileFullPath,$SQLInstanceName) }
                'Uninstall' { $this.Uninstall($SQLFileFullPath,$SQLInstanceName) }
                'Reinstall' { $this.Uninstall($SQLFileFullPath,$SQLInstanceName) ; $this.Install($SQLFileFullPath,$SQLInstanceName) }
            }
            # Set the boolean to true
            $this.DeploymentIsSuccesful = $true
        }

        ####################################################################################################
    
        # Add the ValidateInput method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInput -Value {
            # Validate the string
            if (Test-Object -IsEmpty $this.DeploymentObject.SQLFileName) {
                Write-Host 'ValidateInput: The SQLFileName string is empty.' -ForegroundColor Red
                $this.ValidationIsSuccessful = $false
            }
            # Switch on the boolean
            switch ($this.ValidationIsSuccessful) {
                $true   { Write-Host ('{0}: The validation was successful. The Process method will now start.' -f $this.FunctionName) }
                $false  { Write-Host ('{0}: The validation was NOT successful. The Process method will not start.' -f $this.FunctionName) -ForegroundColor Red }
            }
        }

        ####################################################################################################
    
        # Add the Install method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Install -Value { param([System.String]$SQLFileFullPath,[System.String]$SQLInstanceName)
            try {
                # Run the SQL file
                if ($this.DeploymentObject.RunDuringInstall) {
                    Write-Host ('Running the SQL file. One moment please... ({0})' -f $SQLFileFullPath)
                    Start-Process sqlcmd -ArgumentList "-s .\$SQLInstanceName -E -i $SQLFileFullPath" -Verb RunAs
                } else {
                    Write-Host ('The RunDuringInstall Boolean has been set to $false. No action had been taken. ({0})' -f $SQLFileFullPath)
                }
            }
            catch {
                Write-FullError
            }
        }

    
        # Add the Uninstall method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Uninstall -Value { param([System.String]$SQLFileFullPath,[System.String]$SQLInstanceName)
            try {
                # Run the SQL file
                if ($this.DeploymentObject.RunDuringUninstall) {
                    Write-Host ('Running the SQL file. One moment please... ({0})' -f $SQLFileFullPath)
                    Start-Process sqlcmd -ArgumentList "-s .\$SQLInstanceName -E -i $SQLFileFullPath" -Verb RunAs
                } else {
                    Write-Host ('The RunDuringUninstall Boolean has been set to $false. No action had been taken. ({0})' -f $SQLFileFullPath)
                }
            }
            catch {
                Write-FullError
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

