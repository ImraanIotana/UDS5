####################################################################################################
<#
.SYNOPSIS
    This function searches a file in a folder, and returns the full path of the file.
.DESCRIPTION
    This function is part of the Iotana Deployment Script. It contains references to classes, functions or variables, that are in other files.
    External classes    : -
    External functions  : -
    External variables  : $Global:DeploymentObject
.EXAMPLE
    Get-FileFullPath -Path 'C:\Program Files' -FileName 'MyApplication.exe'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    Version         : 3.9
    Author          : Imraan Noormohamed
    Creation Date   : March 2023
    Last Updated    : November 2023
#>
####################################################################################################

function Get-FileFullPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [System.String]
        $Path = $Global:DeploymentObject.Rootfolder,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [System.String]
        $FileName
    )
    
    begin {
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
            FileToFind              = $FileName
            FolderToSearch          = $Path
            # Output
            OutputObject            = [System.String]::Empty
        }

        ####################################################################################################

        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Add the function details
            Add-Member -InputObject $this -NotePropertyName FunctionDetails -NotePropertyValue ($this.FunctionCircumFix -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments)
            # Write the Begin message
            Write-Verbose ('+++ BEGIN {0}' -f $this.FunctionDetails)
            # Validate the input
            $this.ValidateInput($this.FunctionName)
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
            # File the file
            $this.OutputObject = $this.GetFileFullPath($this.FileToFind,$this.FolderToSearch)
        }

        ####################################################################################################
    
        # Add the ValidateInput method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInput -Value { param([System.String]$FunctionName)
            # Validate the FileName
            if ([System.String]::IsNullOrWhiteSpace($this.FileToFind)) {
                Write-Host ('{0} - ValidateInput: The FileName string is empty.' -f $FunctionName) -ForegroundColor Red
                $this.ValidationIsSuccessful = $false
            }
            # Validate the Path
            if ([System.String]::IsNullOrWhiteSpace($this.FolderToSearch)) {
                Write-Host ('{0} - ValidateInput: The Path string is empty.' -f $FunctionName) -ForegroundColor Red
                $this.ValidationIsSuccessful = $false
            }
            # Switch on the boolean
            switch ($this.ValidationIsSuccessful) {
                $true   { Write-Verbose ('{0} - ValidateInput: The validation was successful. The Process method will now start.' -f $FunctionName) }
                $false  { Write-Host ('{0} - ValidateInput: The validation was NOT successful. The Process method will not start.' -f $FunctionName) -ForegroundColor Red }
            }
        }

        ####################################################################################################
    
        # Add the GetFileFullPath method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetFileFullPath -Value { param([System.String]$FileToFind,[System.String]$FolderToSearch)
            # Search the file
            Write-Verbose ('GetFileFullPath: Searching for the file ({0}) in the folder ({1}) and all subfolders...' -f $FileToFind,$FolderToSearch)
            [System.IO.FileInfo[]]$FoundFileObjects = Get-ChildItem -Path $FolderToSearch -Recurse -Filter $FileToFind -ErrorAction SilentlyContinue
            # Switch on the amount of found files
            switch ($FoundFileObjects.Count) {
                {$_ -eq 0} {
                    # Write the message
                    Write-Host ('GetFileFullPath: The file ({0}) was not found in the folder ({1}) or any subfolders.' -f $FileToFind, $FolderToSearch) -ForegroundColor Red
                }
                {$_ -eq 1} {
                    # Return the file path
                    [System.String]$FileFullPath = $FoundFileObjects[0].FullName
                    Write-Host ('GetFileFullPath: The file was found. The full path is: ({0})' -f $FileFullPath)
                    $FileFullPath
                }
                {$_ -gt 1} {
                    # If multiple files were found, return the first one
                    [System.String]$FileFullPath = $FoundFileObjects[0].FullName
                    Write-Warning ('GetFileFullPath: Multiple files with the filename ({0}) were found. The first one will be returned: ({1})' -f $FileToFind,$FileFullPath)
                    $FileFullPath
                }
            }
        }
    
        # Add the GetFileWithShortestPath method (In development)
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetFileWithShortestPath -Value { param([System.IO.FileInfo[]]$FoundFileObjects)
            # Write the End message
            Write-Verbose ('___ END {0}' -f $this.FunctionDetails)
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


