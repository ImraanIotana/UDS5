####################################################################################################
<#
.SYNOPSIS
    This function test if a font is installed.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Test-FontIsInstalled -Path 'C:\Demo\MyFont.ttf'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    Version         : 5.5.1
    Author          : Imraan Iotana
    Creation Date   : September 2025
    Last Update     : September 2025
#>
####################################################################################################

function Test-FontIsInstalled {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path of the font that will be handled.')]
        [Alias('FilePath','FontPath')]
        [System.String]
        $Path,

        [Parameter(Mandatory=$false,HelpMessage='Switch for writing the details to the host.')]
        [System.Management.Automation.SwitchParameter]
        $OutHost,

        [Parameter(Mandatory=$false,HelpMessage='Switch for returning the result as a boolean.')]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Function
        [System.String[]]$FunctionDetails   = @($MyInvocation.MyCommand,$PSCmdlet.ParameterSetName,$PSBoundParameters.GetEnumerator())
        [System.String]$FunctionName        = $FunctionDetails[0]
        # Output
        [System.Boolean]$OutputObject       = $null
        # Handlers
        [System.String]$WindowsFontsFolder  = (Join-Path -Path $ENV:windir -ChildPath 'Fonts')
        [System.String]$FontsRegistryKey    = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        function Test-FontInWindowsFolder { param([System.String]$FontFileName)
            # Check if the file is in the fonts folder
            [System.String]$FontInWindowsFolderPath = (Get-ChildItem -Path $WindowsFontsFolder -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $FontFileName }).FullName
            # Write the message
            if ($OutHost) {
                if ($FontInWindowsFolderPath) {
                    Write-Success ('[{0}]: The Font is present in the Fonts folder: ({1})' -f $FunctionName,$FontInWindowsFolderPath)
                } else {
                    Write-Fail ('[{0}]: The Font is NOT present in the Fonts folder: ({1})' -f $FunctionName,$FontFileName)
                }
            }
            # Return the result
            if ($FontInWindowsFolderPath) { $true } else { $false }
        }

        function Test-FontInRegistry { param([System.String]$FontFileName)
            # Check if the file is in the registry
            [PSCustomObject[]]$AllPropertyObjects = Get-ItemProperty -Path $FontsRegistryKey
            foreach ($Object in $AllPropertyObjects) {
                $ObjectProperties = $Object.PSObject.Properties
                if ($ObjectProperties.Value -eq $FontFileName) {
                    [System.Boolean]$FontFoundInRegistry = $true
                    [System.String]$PropertyName = ($ObjectProperties | Where-Object { $_.Value -eq $FontFileName }).Name
                }
            }
            # Write the message
            if ($OutHost) {
                if ($FontFoundInRegistry) {
                    Write-Success ('[{0}]: The Font is present in the Registry: ({1})' -f $FunctionName,$PropertyName)
                } else {
                    Write-Fail ('[{0}]: The Font is NOT present in the Registry: ({1})' -f $FunctionName,$FontFileName)
                }
            }
            # Return the result
            if ($FontFoundInRegistry) { $true } else { $false }
        }

        ####################################################################################################
    }
    
    process {
        # Get the filename
        Write-Verbose ('[{0}]: Getting the filename of the font... ({1})' -f $FunctionName,$Path)
        [System.String]$FontFileName = (Get-Item -Path $Path).Name
        # Test if the font is installed
        [System.Boolean]$FontInWindowsFolder    = Test-FontInWindowsFolder -FontFileName $FontFileName
        [System.Boolean]$FontInRegistry         = Test-FontInRegistry -FontFileName $FontFileName
        # Write the message
        if ($OutHost) {
            if ($FontInWindowsFolder -and $FontInRegistry)          { Write-Success ('[{0}]: The Font is installed: ({1})' -f $FunctionName,$FontFileName) }
            if ($FontInWindowsFolder -and (-Not($FontInRegistry)))  { Write-Fail ('[{0}]: The Font is present in the Fonts folder, but NOT in the Registry: ({1})' -f $FunctionName,$FontFileName) }
            if ((-Not($FontInWindowsFolder)) -and $FontInRegistry)  { Write-Fail ('[{0}]: The Font is present in the Registry, but NOT in the Fonts folder: ({1})' -f $FunctionName,$FontFileName) }
            if ((-Not($FontInWindowsFolder)) -and (-Not($FontInRegistry)))  { Write-Fail ('[{0}]: The Font is NEITHER present in the Registry, NOR in the Fonts folder: ({1})' -f $FunctionName,$FontFileName) }
        }
        # Set the output
        $OutputObject = if ($FontInWindowsFolder -and $FontInRegistry) { $true } else { $false }
    }
    
    end {
        # Return the output
        if ($PassThru) { $OutputObject }
    }
}

### END OF SCRIPT
####################################################################################################
