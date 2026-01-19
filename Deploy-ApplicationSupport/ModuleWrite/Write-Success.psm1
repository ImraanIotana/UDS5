####################################################################################################
<#
.SYNOPSIS
    This function write a line to the host, in the colors assigned to this action.
.DESCRIPTION
    This function is self-contained and does not refer to functions, variables or classes, that are in other files.
.EXAMPLE
    Write-Success "Hello World!"
.INPUTS
    [System.String]
.OUTPUTS
    This function returns no stream output.
.NOTES
    Version         : 5.5.1
    Author          : Imraan Iotana
    Creation Date   : September 2025
    Last Update     : September 2025
#>
####################################################################################################

function Write-Success {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0,HelpMessage='The message that will be written to the host.')]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $Message
    )

    begin {
        # Handlers
        [System.String]$TimeStamp               = Get-TimeStamp -ForLogging
        [System.String]$MessageWithTimeStamp    = "[$TimeStamp] $Message"
    }
    
    process {
        # Write the message
        Write-Host $MessageWithTimeStamp -ForegroundColor White -BackgroundColor DarkGreen
        #Write-Host $Message -ForegroundColor White -BackgroundColor DarkGreen
    }
    
    end {
    }
}

### END OF FUNCTION
####################################################################################################