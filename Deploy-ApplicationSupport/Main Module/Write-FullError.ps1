####################################################################################################
<#
.SYNOPSIS
    This function writes detailed error information to the host.
.DESCRIPTION
    This function is part of the IT Assistant. It contains references to classes, functions or variables, that are in other files.
    External classes    : -
    External functions  : -
    External variables  : $Global:ApplicationObject
.EXAMPLE
    Write-FullError -Message 'The file could not be found.'
.EXAMPLE
    Write-FullError -UnknownError
.EXAMPLE
    Write-FullError
.INPUTS
    [System.String]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    This function returns no stream-output.
.NOTES
    Version         : 5.0.11
    Author          : Imraan Iotana
    Creation Date   : June 2023
    Last Update     : May 2025
#>
####################################################################################################

function Write-FullError {
    [CmdletBinding(DefaultParameterSetName='UnknownError')]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='Message',Position=0,HelpMessage='Your custom message that will be written in yellow.')]
        [System.String]
        $Message,

        [Parameter(Mandatory=$false,ParameterSetName='UnknownError',Position=0,HelpMessage='Switch for using the default message for unknown errors.')]
        [System.Management.Automation.SwitchParameter]
        $UnknownError
    )
    
    begin {
        ####################################################################################################
        ### MAIN OBJECT ###

        # Set the main object
        [PSCustomObject]$Local:MainObject = @{
            # Function
            ParameterSetName        = [System.String]$PSCmdlet.ParameterSetName
            # Log Handlers
            TimeStamp               = [System.String]((Get-Date -UFormat '%Y%m%d%R') -replace ':','')
            LogFolder               = [System.String]($Global:DeploymentObject.LogFolder)
            LogFileNameCircumFix    = [System.String]'Packaging Assistant Errorlog - {0}.log'
            # Text Handlers
            UnknownError            = [System.String]'An unknown error has occured.'
            InvokingHierarchy       = [System.String]'InvocationOrder    : '
            # Input
            InputMessage            = $Message
        }

        ####################################################################################################
        ### MAIN FUNCTION METHODS ###
        
        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Add the logfile path to the main object
            [System.String]$LogFileName = ($this.LogFileNameCircumFix -f $this.TimeStamp)
            Add-Member -InputObject $this -NotePropertyName LogFilePath -NotePropertyValue (Join-Path -Path $this.LogFolder -ChildPath $LogFileName)
            # Add the InvokingFunctionHierarchy to the main object
            $this.AddInvokingFunctionHierarchyToMainObject()
        }

        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # Write the full error
            $this.WriteFullError()
        }

        ####################################################################################################
        ### MAIN PROCESSING METHODS ###

        # Add the WriteFullError method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name WriteFullError -Value {
            # Set the error message
            [System.String]$ErrorMessage = switch ($this.ParameterSetName) {
                'Message'       { $this.InputMessage }
                'UnknownError'  { $this.UnknownError }
            }
            # Set the full name of the error
            [System.String]$ErrorFullName = $Error[0].Exception.GetType().FullName
            # In case of an unknown error, write all error details
            if ($this.ParameterSetName -eq 'UnknownError') {
                Start-Transcript -Path $this.LogFilePath -Append
                Write-Host ('ERRORMESSAGE       : {0}' -f $ErrorMessage) -ForegroundColor Yellow
                Write-Host ('ExceptionType      : ') -ForegroundColor Yellow -NoNewline
                Write-Host $ErrorFullName
                Write-Host $this.InvokingHierarchy -ForegroundColor Yellow -NoNewline
                Write-Host $this.InvokingFunctionHierarchy
                Write-Host ('Details            :') -ForegroundColor Yellow
                $Error[0] | Out-Host
                Write-Host
                Stop-Transcript
                # Open the logfolder
                Open-Folder -SelectItem $this.LogFilePath
            } else {
                # Else only write the error message
                Write-Host ('ERRORMESSAGE: {0}' -f $ErrorMessage) -ForegroundColor Yellow
                Write-Host $this.InvokingHierarchy -ForegroundColor Yellow -NoNewline
                Write-Host $this.InvokingFunctionHierarchy
            }
        }

        ####################################################################################################
        ### SUPPORTING METHODS ###

        # Add the AddInvokingFunctionHierarchyToMainObject method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name AddInvokingFunctionHierarchyToMainObject -Value {
            # Set the indeces of the invoking functions
            [int[]]$IndecesOfInvokingFunctions = @(0..20)
            # Get the array of the invoking functions
            [string[]]$InvokingFunctionsArray = (Get-PSCallStack).Command
            # Fill the InvokingFunctionHierarchy
            [System.String]$InvokingFunctionHierarchy = [System.String]::Empty
            $IndecesOfInvokingFunctions.ForEach({
                # Get the name of the invoking function
                [System.String]$InvokingFunctionName = $InvokingFunctionsArray[$_]
                if ($InvokingFunctionName) { $InvokingFunctionHierarchy += ('[{0}] {1} ' -f $_, $InvokingFunctionName) }
            })
            # Add the InvokingFunctionHierarchy to the main object
            Add-Member -InputObject $this -NotePropertyName InvokingFunctionHierarchy -NotePropertyValue $InvokingFunctionHierarchy
        }

        ####################################################################################################

        $Local:MainObject.Begin()
    }
    
    process {
        $Local:MainObject.Process()
    }
    
    end {
    }
}

### END OF SCRIPT
####################################################################################################
