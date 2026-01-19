####################################################################################################
<#
.SYNOPSIS
    This function confirms/validates an object
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Confirm-Object -MandatoryString $MyStringVariable
.INPUTS
    [System.String]
    [System.String[]]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.1
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : August 2025
#>
####################################################################################################

function Confirm-Object {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='ValidateMandatoryString',HelpMessage='The mandatory string that will be validated')]
        [Parameter(Mandatory=$true,ParameterSetName='MandatoryStringInValidateSet',HelpMessage='The mandatory string that will be validated')]
        [AllowEmptyString()]
        [System.String]
        $MandatoryString,

        [Parameter(Mandatory=$true,ParameterSetName='MandatoryStringInValidateSet',HelpMessage='The validate set, against whom the mandatory string will be validated')]
        [System.String[]]
        $ValidateSet,

        [Parameter(Mandatory=$true,ParameterSetName='ValidateMandatoryItem',HelpMessage='The mandatory item path that will be validated')]
        [AllowEmptyString()]
        [System.String]
        $MandatoryItem,

        [Parameter(Mandatory=$true,ParameterSetName='ValidateMandatoryArray',HelpMessage='The mandatory array that will be validated')]
        [AllowEmptyCollection()]
        [System.Object[]]
        $MandatoryArray,

        [Parameter(Mandatory=$true,ParameterSetName='ValidateGUID',HelpMessage='The GUID that will be validated')]
        [AllowEmptyString()]
        [System.String]
        $GUID
    )
    
    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Function
        [System.String[]]$FunctionDetails   = @($MyInvocation.MyCommand,$PSCmdlet.ParameterSetName,$PSBoundParameters.GetEnumerator())
        [System.String]$FunctionName        = $FunctionDetails[0]
        # Output
        [System.Boolean]$OutputObject       = $null


        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        function Test-MandatoryString { param([System.String]$StringToValidate)
            # If the string is populated then return true, else return false
            Write-Verbose ('[Test-MandatoryString]: Testing if the string is populated: ({0})' -f $StringToValidate)
            if ([System.String]::IsNullOrEmpty($StringToValidate)) {
                Write-Fail ('[Test-MandatoryString]: The string is empty.')
                $false
            } else {
                Write-Verbose ('[Test-MandatoryString]: The string is populated: ({0})' -f $StringToValidate)
                $true
            }
        }

        function Test-MandatoryArray { param([System.Object[]]$ArrayToValidate)
            # If the array is populated then return true, else return false
            Write-Verbose ("[Test-MandatoryArray]: Testing if the array is populated: ($ArrayToValidate)")
            if ($ArrayToValidate.Count -eq 0) {
                Write-Fail ('[Test-MandatoryArray]: The array is empty.')
                $false
            } else {
                Write-Verbose ("[Test-MandatoryArray]: The array is populated: ($ArrayToValidate)")
                $true
            }
        }
        
        function Test-MandatoryStringInValidateSet { param([System.String]$StringToValidate,[System.String[]]$ValidateSetArray)
            try {
                # Test if the string is empty
                if (-Not(Test-MandatoryString -StringToValidate $StringToValidate)) { $false ; Return }
                # Validate the string
                Write-Verbose ("[{0}]: Testing if the string ({1}) is part of the ValidateSet: ($ValidateSetArray)" -f $FunctionName,$StringToValidate)
                if ($ValidateSetArray -contains $StringToValidate) {
                    Write-Verbose ("[{0}]: The string ({1}) is part of the ValidateSet: ($ValidateSetArray)" -f $FunctionName,$StringToValidate)
                    $true
                } else {
                    Write-Fail ("[{0}]: The string ({1}) is NOT part of the ValidateSet: ($ValidateSetArray)" -f $FunctionName,$StringToValidate)
                    $false
                }
            }
            catch { Write-FullError }
        }
        
        function Test-MandatoryItem { param([System.String]$ItemPathToValidate)
            try {
                # Validate the string
                if (-Not(Test-MandatoryString -StringToValidate $ItemPathToValidate)) { $false ; Return }
                # Validate the path
                Write-Verbose ('[{0}]: Testing if the path exists: ({1})' -f $FunctionName,$ItemPathToValidate)
                if (Test-Path -Path $ItemPathToValidate) {
                    Write-Verbose ('[{0}]: The path exists: ({1})' -f $FunctionName,$ItemPathToValidate)
                    $true
                } else {
                    Write-Fail ('[{0}]: The path does not exist, or could not be reached: ({1})' -f $FunctionName,$ItemPathToValidate)
                    $false
                }
            }
            catch { Write-FullError }
        }

        # Under construction
        function Test-GUIDIsValid { param([System.String]$GUIDAsString)
            try {
                # Parse the string
                Write-Host ('[{0}]: Validating the GUID: ({1})' -f $FunctionName,$GUIDAsString)
                #if ([System.Guid]::TryParse($GUIDAsString,[ref]$null)) {Write-Host 'success'} else { Write-Host 'faal'}
                $null = New-Object System.Guid -ArgumentList $GUIDAsString -ErrorAction Stop
                #[System.Guid]::TryParse($GUIDAsString,[ref]$null) -ErrorAction Stop
                #[System.Guid]::Parse($GUIDAsString) | Out-Null
                # Return true
                Write-Success ('[{0}]: The GUID meets the GUID-requirements of 2 curly braces and 32 digits with 4 dashes: ({1})' -f $FunctionName,$GUIDAsString)
                $true
            }
            catch [System.Management.Automation.MethodInvocationException] {
                # Write the error
                Write-Fail ('[{0}]: The GUID does not meet the GUID-requirements of 2 curly braces and 32 digits with 4 dashes {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}: ({1})' -f $FunctionName,$GUIDAsString)
                $false
            }
            catch {
                # Write the error
                Write-FullError
                $false
            }
        }

        ####################################################################################################
    }
    
    process {
        try {
            # Switch on the ParameterSetName
            $OutputObject = switch ($FunctionDetails[1]) {
                'ValidateMandatoryString'       { Test-MandatoryString -StringToValidate $MandatoryString }
                'MandatoryStringInValidateSet'  { Test-MandatoryStringInValidateSet -StringToValidate $MandatoryString -ValidateSetArray $ValidateSet }
                'ValidateMandatoryItem'         { Test-MandatoryItem -ItemPathToValidate $MandatoryItem }
                'ValidateMandatoryArray'        { Test-MandatoryArray -ArrayToValidate $MandatoryArray }
                'ValidateGUID'                  { Test-GUIDIsValid -GUIDAsString $GUID } # Under construction
            }
        }
        catch {
            Write-FullError
        }
    }
    
    end {
        # Return the output
        $OutputObject
    }
}

### END OF SCRIPT
####################################################################################################
