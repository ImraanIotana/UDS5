####################################################################################################
<#
.SYNOPSIS
    This function installs a font.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Install-Font -Path 'C:\Demo\MyFont.ttf'
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

function Install-Font {
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

        function Install-FontInternalFunction {
            if ($OutHost) { Write-Busy ('[{0}]: Copying the font to the Fonts folder... ({1})' -f $FunctionName,$FontFileName) }
            Copy-Item -Path $Path -Destination $WindowsFontsFolder -Force
            if ($OutHost) { Write-Busy ('[{0}]: Adding the font to the Registry... ({1})' -f $FunctionName,$FontFriendlyName) }
            # Check if the file is in the registry
            [PSCustomObject[]]$AllPropertyObjects = Get-ItemProperty -Path $FontsRegistryKey
            foreach ($Object in $AllPropertyObjects) {
                $ObjectProperties = $Object.PSObject.Properties
                if ($ObjectProperties.Value -eq $FontFileName) {
                    [System.Boolean]$FontFoundInRegistry = $true
                    [System.String[]]$PropertyNames = ($ObjectProperties | Where-Object { $_.Value -eq $FontFileName }).Name
                }
            }
            # Remove the existing property before adding the new one
            $PropertyNames | ForEach-Object { if ($_) { Remove-ItemProperty -Path $FontsRegistryKey -Name $_ -Force } }
            Set-ItemProperty -Path $FontsRegistryKey -Name $FontFriendlyName -Value $FontFileName -Force
        }


        ####################################################################################################
    }
    
    process {
        # Install the font
        [System.Boolean]$FontIsInstalled = Test-FontIsInstalled -Path $Path -PassThru
        [System.Boolean]$InstallIsSuccessful = if ($FontIsInstalled) {
            if ($Force) {
                Install-FontInternalFunction
                Test-FontIsInstalled -Path $Path -PassThru
            } else {
            if ($OutHost) { Write-Success ('[{0}]: The Font is already installed. The installation will be skipped: ({1})' -f $FunctionName,$FontFileName) }
                $true
            }
        } else {
            Install-FontInternalFunction
            Test-FontIsInstalled -Path $Path -PassThru
        }
        # Set the output
        $OutputObject = $InstallIsSuccessful
    }
    
    end {
        # Return the output
        if ($PassThru) { $OutputObject }
    }
}

### END OF SCRIPT
####################################################################################################
