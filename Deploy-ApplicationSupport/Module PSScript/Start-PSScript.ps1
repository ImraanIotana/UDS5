####################################################################################################
<#
.SYNOPSIS
    This function runs a PS1 script.
.DESCRIPTION
    This function is self-contained and does not refer to functions, variables or classes, that are in other files.
.EXAMPLE
    Start-PSScript -Install
.EXAMPLE
    Start-PSScript -Test
.INPUTS
    [System.String]
    [System.String[]]
    [System.Boolean[]]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 3.3
    Author          : Imraan Noormohamed
    Creation Date   : October 2023
    Last Update     : October 2023
#>
####################################################################################################

function Start-PSScript {
    [CmdletBinding()]
    param (
        # Path of the PS1 file
        [Parameter(Mandatory=$true)]
        [System.String]
        $PS1Path,

        # ArgumentList
        [Parameter(Mandatory=$false)]
        [System.String[]]
        $ArgumentList,

        # SuccessExitCodes
        [Parameter(Mandatory=$false)]
        [System.Boolean[]]
        $SuccessExitCodes = @(0)
    )
    
    begin {
        # Create the main object
        [PSCustomObject]$Local:MainObject = @{
            # Function
            FunctionName        = [System.String]$MyInvocation.MyCommand
            FunctionArguments   = [System.String]$PSBoundParameters.GetEnumerator()
            ParameterSetName    = [System.String]$PSCmdlet.ParameterSetName
            FunctionCircumFix   = [System.String]'Function: [{0}] ParameterSetName: [{1}] Arguments: {2}'
            # Handlers
            ValidationIsSuccessful = [System.Boolean]$true
            PowerShellExePath   = [System.String](Join-Path -Path ([System.Environment]::SystemDirectory) -ChildPath 'WindowsPowerShell\v1.0\powershell.exe')
            # Input
            PS1Path             = $PS1Path
            ArgumentList        = $ArgumentList
            SuccessExitCodes    = $SuccessExitCodes
            # Output
            OutputObject        = [System.Boolean]$null
        }

        ####################################################################################################
        
        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Add the function details
            Add-Member -InputObject $this -NotePropertyName FunctionDetails -NotePropertyValue ($this.FunctionCircumFix -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments)
            # Write the Begin message
            Write-Verbose ('+++ BEGIN {0}' -f $this.FunctionDetails)
        }
    
        # Add the End method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name End -Value {
            # Write the End message
            Write-Verbose ('___ END {0}' -f $this.FunctionDetails)
        }

        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # Validate the input
            $this.ValidateInput()
            # If the validation was successful
            if ($this.ValidationIsSuccessful) {
                # Write the success message
                Write-Verbose 'The validation was successful. The Process method will now start.'
                # Run the script
                $this.OutputObject = $this.RunScriptWITHArguments($this.PS1Path,$this.ArgumentList)
            } else {
                # Write the error
                Write-Verbose 'The validation was NOT successful. The Process method will not start.'
            }
        }

        ####################################################################################################

        # Add the ValidateInput method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInput -Value {
            # Write the message
            Write-Verbose 'This function has no input validation.'
        }

        ####################################################################################################

        # Add the RunScriptWITHArguments method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name RunScriptWITHArguments -Value { param([System.String]$PS1Path,[System.String[]]$ArgumentList)
            # If the ArgumentList is empty
            if ($ArgumentList.Count -eq 0) {
                # Run the RunScriptWITHOUTArguments method
                $this.RunScriptWITHOUTArguments($PS1Path)
            } else {
                # Run the script
                [System.String]$FilePathArgument = ('-File "{0}" ' -f $PS1Path)
                $ArgumentList = $FilePathArgument + $ArgumentList
                Write-Host ("RunScriptWITHArguments: Running the script ($PS1Path) WITH arguments ($ArgumentList). One moment please...") -ForegroundColor Green
                [System.Int32]$ExitCode = Start-Process -FilePath $this.PowerShellExePath -ArgumentList $ArgumentList -Wait
                # Write the result
                [System.Boolean]$ProcessIsSuccesful = ($ExitCode -in $this.SuccessExitCodes)
                Write-Host ('RunScriptWITHArguments: The ExitCode is: ({0})' -f $ExitCode)
                # Return the result
                $ProcessIsSuccesful
            }
        }

        # Add the RunScriptWITHOUTArguments method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name RunScriptWITHOUTArguments -Value { param([System.String]$PS1Path)
            # Run the script
            Write-Host ('RunScriptWITHOUTArguments: Running the script WITHOUT arguments. One moment please... ({0})' -f $PS1Path)
            [System.Int32]$ExitCode = & $PS1Path
            # Write the result
            [System.Boolean]$ProcessIsSuccesful = ($ExitCode -in $this.SuccessExitCodes)
            Write-Host ('RunScriptWITHOUTArguments: The ExitCode is: ({0})' -f $ExitCode)
            # Return the result
            $ProcessIsSuccesful
        }

        ####################################################################################################

        #region BEGIN
        $Local:MainObject.Begin()
        #endregion BEGIN
    }
    
    process {
        #region PROCESS
        $Local:MainObject.Process()
        #endregion PROCESS
    }

    end {
        #region END
        $Local:MainObject.End()
        # Return the output
        $Local:MainObject.OutputObject
        #endregion END
    }
}
