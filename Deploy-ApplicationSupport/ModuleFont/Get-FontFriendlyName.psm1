####################################################################################################
<#
.SYNOPSIS
    This function obtains the friendly name of a font file.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Get-FontFriendlyName -Path 'C:\Demo\MyFont.ttf'
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

function Get-FontFriendlyName {
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
        [System.String]$OutputObject        = [System.String]::Empty

        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        function Get-FriendlyName { param([System.String]$FontFilePath = $Path)
            # Load the assembly (When running this script with SCCM an error appears about GlyphTypeface. To solve this the Assembly must be loaded explicitly.)
            Add-Type -AssemblyName PresentationCore
            # Get the details of the font
            Write-Verbose ('[{0}]: Getting the details of the font... ({1})' -f $FunctionName,$FontFilePath)
            # Get the glyph type face of the font
            [System.Windows.Media.GlyphTypeface]$GlyphTypeface = [System.Windows.Media.GlyphTypeface]::new([uri]::new($FontFilePath))
            # Get the family name and add it to the font details hashtable
            if ($null -eq ($FamilyName = $GlyphTypeface.Win32FamilyNames['en-us'])) { $FamilyName = $GlyphTypeface.Win32FamilyNames.Values.Item(0) }
            Write-Verbose ('[{0}]: The FamilyName is: ({1})' -f $FunctionName,$FamilyName)
            # Get the font weight and add it to the font details hashtable
            [System.Windows.FontWeight]$FontWeight = $GlyphTypeface.Weight
            Write-Verbose ('[{0}]: The FontWeight is: ({1})' -f $FunctionName,$FontWeight)
            # Get the font style and add it to the font details hashtable
            [System.Windows.FontStyle]$FontStyle = $GlyphTypeface.Style
            Write-Verbose ('[{0}]: The FontStyle is: ({1})' -f $FunctionName,$FontStyle)
            # Get the font type and add it to the font details hashtable
            [System.String]$FontFileExtension = (Get-Item $FontFilePath).Extension
            [System.String]$FontType = switch ($FontFileExtension) {
                '.ttf' { 'TrueType' }
                '.otf' { 'OpenType' }
                Default { Write-Fail ('[{0}]: No FontType has been defined for this extension: ({0})' -f $FunctionName,$FontFileExtension) }
            }
            # Create the friendly name
            [System.String]$FontFriendlyName = $FamilyName
            if ($FontWeight -ne 'Normal') { $FontFriendlyName = $FontFriendlyName + " $FontWeight" }
            if ($FontStyle -ne 'Normal') { $FontFriendlyName = $FontFriendlyName + " $FontStyle" }
            $FontFriendlyName = $FontFriendlyName + " ($FontType)"
            # Write the message
            if ($OutHost) {
                # Write the FontFriendlyName
                [System.String]$FileName = Split-Path -Path $Path -Leaf
                Write-Success ('[{0}]: The FontFriendlyName of ({1}) is: ({2})' -f $FunctionName,$FileName,$FontFriendlyName)
            }
            # Return the FontFriendlyName
            $FontFriendlyName
        }

        ####################################################################################################
    }
    
    process {
        # Set the output
        $OutputObject = Get-FriendlyName
    }
    
    end {
        # Return the output
        if ($PassThru) { $OutputObject }
    }
}

### END OF SCRIPT
####################################################################################################
