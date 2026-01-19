####################################################################################################
<#
.SYNOPSIS
    This function performs validation functions for the Universal Deployment Script.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
    External classes    : -
    External functions  : Test-Object, Get-FileFullPath, Write-FullError
    External variables  : -
.EXAMPLE
    Validate-Object -MandatoryFile 'MyApplication.msi'
.EXAMPLE
    Validate-Object -GUID {6B29FC40-CA47-1067-B31D-00DD010662DA}
    (This will return true)
.EXAMPLE
    Validate-Object -GUID 6B29FC40-CA47-1067-B31D-00DD010662DA
    (This will return false)
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 4.6
    Author          : Imraan Iotana
    Creation Date   : September 2024
    Last Update     : September 2024
#>
####################################################################################################

function Validate-Object {
    [CmdletBinding()]
    param (
        # The name of the file that will be validated
        [Parameter(Mandatory=$true,ParameterSetName='ValidateMandatoryFile')]
        [System.String]
        $MandatoryFile,
        
        # The GUID that will be validated
        [Parameter(Mandatory=$true,ParameterSetName='ValidateGUIDFormat')]
        [System.String]
        $GUID
    )
    
    begin {
        ####################################################################################################
        ### MAIN OBJECT ###

        # Create the main object
        [PSCustomObject]$Local:MainObject = @{
            # Function
            FunctionName            = [System.String]$MyInvocation.MyCommand
            FunctionArguments       = [System.String]$PSBoundParameters.GetEnumerator()
            ParameterSetName        = [System.String]$PSCmdlet.ParameterSetName
            FunctionCircumFix       = [System.String]'Function: [{0}] ParameterSetName: [{1}] Arguments: {2}'
            # Input
            MandatoryFileToValidate = $MandatoryFile
            GUIDToValidate          = $GUID
            # Output
            OutputObject            = [System.Boolean]$null
        }

        ####################################################################################################
        ### MAIN FUNCTION METHODS ###

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
            # Switch on the ParameterSetName
            $this.OutputObject = switch ($this.ParameterSetName) {
                'ValidateMandatoryFile' { $this.ValidateMandatoryFileProcess($this.MandatoryFileToValidate) }
                'ValidateGUIDFormat'    { $this.ValidateGUIDProcess($this.GUIDToValidate) }
            }
        }

        ####################################################################################################
        ### MAIN PROCESSING METHODS ###

        # Add the ValidateMandatoryFileProcess method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateMandatoryFileProcess -Value { param([System.String]$FileName)
            # If the string is empty, return false
            if ($this.TestStringIsEmpty($FileName)) { $false }
            # Else test if the file exists
            else { $this.TestFileExistence($FileName) }
        }

        # Add the ValidateGUIDProcess method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateGUIDProcess -Value { param([System.String]$GUIDAsString)
            try {
                # Parse the string
                Write-Verbose ('ValidateGUIDProcess: Validating the GUID: {0}' -f $GUIDAsString)
                [System.Guid]::Parse($GUIDAsString) | Out-Null
                # Return true
                Write-Verbose ('ValidateGUIDProcess: The GUID {0} meets the GUID-requirements of 2 curly braces and 32 digits with 4 dashes.' -f $GUIDAsString)
                $true
            }
            catch [System.Management.Automation.MethodInvocationException] {
                # Write the error
                Write-Host ('ValidateGUIDProcess: The GUID does not meet the GUID-requirements of 2 curly braces and 32 digits with 4 dashes {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}: {0}' -f $GUIDAsString)
                $false
            }
            catch {
                # Write the error
                Write-FullError
                $false
            }
        }

        ####################################################################################################
        ### SUPPORTING METHODS ###

        # Add the TestStringIsEmpty method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestStringIsEmpty -Value { param([System.String]$StringToTest)
            # Write the message
            Write-Verbose ('TestStringIsEmpty: Testing if the string is empty... ({0})' -f $StringToTest)
            # If the string is empty
            if (Test-Object -IsEmpty $StringToTest) {
                # Write the message
                Write-Host ('TestStringIsEmpty: The string is empty. ({0})' -f $StringToTest)
                # Return true
                $true
            }
        }

        # Add the TestFileExistence method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestFileExistence -Value { param([System.String]$FileName)
            # Write the message
            Write-Verbose ('TestFileExistence: Testing if the file exists in the sourcefiles... ({0})' -f $FileName)
            # Search the file in the sourcefiles
            [System.String]$FilePath = Get-FileFullPath -FileName $FileName
            # If the file can not be found
            if (Test-Object -IsEmpty $FilePath) {
                # Write the message
                Write-Host ('TestFileExistence: The file could not be found in the sourcefolder, or any of the subfolders. ({0})' -f $FileName) -ForegroundColor Red
                # Return false
                $false
            } else {
                # Write the message
                Write-Verbose ('TestFileExistence: The file was found: ({0})' -f $FilePath)
                # Return true
                $true
            }
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

### END OF SCRIPT
####################################################################################################
