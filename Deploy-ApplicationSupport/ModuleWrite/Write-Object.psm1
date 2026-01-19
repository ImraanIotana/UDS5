
####################################################################################################
<#
.SYNOPSIS
    This function writes an object to the host
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Write-Object $MyVariable
.INPUTS
    [System.Object]
.OUTPUTS
    This function returns no stream-output.
.NOTES
    Version         : 5.5.1
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : September 2025
#>
####################################################################################################

function Write-Object {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage='The object that will be written to the host.')]
        [AllowNull()]
        [AllowEmptyString()]
        $InputObject
    )
    
    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Function
        [System.String[]]$FunctionDetails = @($MyInvocation.MyCommand,$PSCmdlet.ParameterSetName,$PSBoundParameters.GetEnumerator())

        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        function Write-GenericObject { param([System.Object]$GenericObject)
            try { Write-Line ('The value is: "{0}"' -f $GenericObject) -Type Success } catch { Write-FullError }
        }

        function Write-Array { param([System.Object[]]$ArrayToWrite)
            try { Write-Line ('The value is:') -Type Success ; $ArrayToWrite | Foreach-Object { Write-Host $_ } } catch { Write-FullError }
        }

        function Write-PSCustomObject { param([System.Object]$InputObject)
            try { Write-Line ('The value is:') -Type Success ; $InputObject | Out-Host | Format-List } catch { Write-FullError }
        }

        function Write-XmlElement { param([System.Xml.XmlElement]$XmlElement)
            try { Write-Line ('The value is:') -Type Success ; $XmlElement | Out-Host } catch { Write-FullError }
        }

        function Write-XmlDocument { param([System.Xml.XmlDocument]$XmlDocument)
            try { Write-Line ('The value is:') -Type Success ; $XmlDocument | Out-Host } catch { Write-FullError }
        }

        function Write-XmlDocument { param([System.Xml.XmlDocument]$XmlDocument)
            try { Write-Line ('The value is:') -Type Success ; $XmlDocument | Out-Host } catch { Write-FullError }
        }

        ####################################################################################################
    }
    
    process {
        # Validate the input
        if ($null -eq $InputObject) { Write-Line ('{0}: The Object is $null. It can not be written to the host' -f $FunctionDetails[0]) -Type Busy ; Return }
        # Write the message
        [System.String]$InputObjectType = $InputObject.GetType().FullName
        Write-Line ('The InputObject Type is: [{0}]' -f $InputObjectType) -Type Busy
        # Switch on the Type
        foreach ($Object in $InputObject) {
            [System.String]$ObjectType = $Object.GetType().FullName
            Write-Line ('The Object Type is: [{0}]' -f $ObjectType) -Type Busy
            switch ($ObjectType) {
                'System.String'                 { Write-GenericObject $Object }
                'System.Int32'                  { Write-GenericObject $Object }
                'System.Double'                 { Write-GenericObject $Object }
                'System.Boolean'                { Write-GenericObject $Object }
                'System.Collections.Hashtable'  { Write-PSCustomObject $Object }
                'System.IO.FileSystemInfo'      { Write-PSCustomObject $Object }
                'System.IO.DirectoryInfo'       { Write-PSCustomObject $Object }
                'System.__ComObject'            { Write-PSCustomObject $Object }
                'System.Xml.XmlElement'         { Write-XmlElement $Object }
                'System.Xml.XmlDocument'        { Write-XmlDocument $Object }
                'System.Xml.XPathNodeList'      { Write-XmlElement $Object }
                'System.Windows.FontWeight'     { Write-PSCustomObject $Object }
                'System.Windows.FontStyle'      { Write-PSCustomObject $Object }
                'System.Management.Automation.PSCustomObject'  { Write-PSCustomObject $Object }
                'System.Management.Automation.PSNoteProperty'  { Write-PSCustomObject $Object }
                'Microsoft.ConfigurationManagement.ManagementProvider.WqlQueryEngine.WqlResultObject'   { Write-PSCustomObject $InputObject }
                #{$_ -is [System.Object[]]}  { Write-Array $InputObject }
                #{$_ -is [Microsoft.Security.ApplicationId.PolicyManagement.PolicyModel.AppLockerPolicy]}  { Write-PSCustomObject $InputObject }
                default                     { Write-Line ('{0}: This Object Type is not yet defined in this function: [{1}]' -f $FunctionDetails[0],$ObjectType) -Type Fail }
            }
        }
    }
    
    end {
    }
}

### END OF FUNCTION
####################################################################################################
