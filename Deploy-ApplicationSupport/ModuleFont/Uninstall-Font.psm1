####################################################################################################
<#
.SYNOPSIS
    This function uninstalls a font.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Uninstall-Font -Path 'C:\Demo\MyFont.ttf'
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

function Uninstall-Font {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path of the font that will be handled.')]
        [Alias('FilePath')]
        [System.String]
        $Path,

        [Parameter(Mandatory=$false,HelpMessage='Switch for writing the details to the host.')]
        [System.Management.Automation.SwitchParameter]
        $OutHost,

        [Parameter(Mandatory=$false,HelpMessage='Switch for returning the result as a boolean.')]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter(Mandatory=$false,HelpMessage='Switch for installing the font and overwriting current values.')]
        [System.Management.Automation.SwitchParameter]
        $Force
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
        ### SUPPORTING PROPERTIES ###

        # Get the filename of the font
        [System.String]$FontFileName = (Get-Item -Path $Path).Name
        # Get the friendly name of the font
        [System.String]$FontFriendlyName = Get-FontFriendlyName -Path $Path -PassThru

        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        function Remove-FontFromFontsFolder {
            [System.String]$FontInWindowsFolderPath = (Get-ChildItem -Path $WindowsFontsFolder -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $FontFileName }).FullName
            if ($OutHost) { Write-Busy ('[{0}]: Removing the font from the Fonts folder... ({1})' -f $FunctionName,$FontInWindowsFolderPath) }
            if ($FontInWindowsFolderPath) { Remove-Item -Path $FontInWindowsFolderPath -Force }
        }

        function Remove-FontFromRegistry {
            if ($OutHost) { Write-Busy ('[{0}]: Removing the font from the Registry... ({1})' -f $FunctionName,$FontFriendlyName) }
            # Check if the font is in the registry
            [PSCustomObject[]]$AllPropertyObjects = Get-ItemProperty -Path $FontsRegistryKey
            foreach ($Object in $AllPropertyObjects) {
                $ObjectProperties = $Object.PSObject.Properties
                if ($ObjectProperties.Value -eq $FontFileName) {
                    [System.String[]]$PropertyNames = ($ObjectProperties | Where-Object { $_.Value -eq $FontFileName }).Name
                }
            }
            $PropertyNames | ForEach-Object { if ($_) { Remove-ItemProperty -Path $FontsRegistryKey -Name $_ -Force } }
        }


        ####################################################################################################
    }
    
    process {
        # Uninstall the font
        [System.Boolean]$FontIsInstalled = Test-FontIsInstalled -Path $Path -PassThru
        if ($FontIsInstalled) {
            Remove-FontFromFontsFolder
            Remove-FontFromRegistry
        } else {
            if ($Force) {
                Remove-FontFromFontsFolder
                Remove-FontFromRegistry
            } else {
                Write-Success ('[{0}]: The Font is not installed. The uninstall will be skipped: ({1})' -f $FunctionName,$FontFileName)
            }
        }
        # Validate the uninstall
        [System.Boolean]$UninstallIsSuccessful = (-Not(Test-FontIsInstalled -Path $Path -PassThru))
        # Set the output
        $OutputObject = $UninstallIsSuccessful
    }
    
    end {
        # Return the output
        if ($PassThru) { $OutputObject }
    }
}

### END OF SCRIPT
####################################################################################################
