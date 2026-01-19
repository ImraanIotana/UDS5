####################################################################################################
<#
.SYNOPSIS
    This function test if an object is empty or populated.
.DESCRIPTION
    This function is self-contained and does not refer to functions, variables or classes, that are in other files.
.EXAMPLE
    Test-Object -IsEmpty $MyString
.EXAMPLE
    Test-Object -IsPopulated $MyArray
.INPUTS
    [System.Object]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 1.0
    Author          : Imraan Iotana
    Creation Date   : July 2023
    Last Updated    : August 2023
#>
####################################################################################################

function Test-Object {
    [CmdletBinding()]
    param (
        # Object to test if it is empty
        [Parameter(Mandatory=$true,ParameterSetName='TestIfEmpty',Position=0)]
        [AllowNull()]
        [System.Object]
        $IsEmpty,

        # Object to test if it is populated
        [Parameter(Mandatory=$true,ParameterSetName='TestIfPopulated',Position=0)]
        [AllowNull()]
        [System.Object]
        $IsPopulated
    )
    
    begin {
        # Set the main object
        [PSCustomObject]$Local:MainObject = @{
            # Function
            FunctionName        = [System.String]$MyInvocation.MyCommand
            FunctionArguments   = [System.String]$PSBoundParameters.GetEnumerator()
            ParameterSetName    = [System.String]$PSCmdlet.ParameterSetName
            # Input
            IsEmpty             = $IsEmpty
            IsPopulated         = $IsPopulated
            # Output
            OutputObject        = [System.Boolean]$null
        }

        ####################################################################################################
        
        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Write the Begin message
            Write-Verbose ('+++ BEGIN Function: [{0}] ParameterSetName: [{1}] Arguments: {2}' -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments)
            # Add the Object to test
            [System.Object]$ObjectToTest = switch ($this.ParameterSetName) {
                'TestIfEmpty'       { $this.IsEmpty }
                'TestIfPopulated'   { $this.IsPopulated }
            }
            Add-Member -InputObject $this -NotePropertyName ObjectToTest -NotePropertyValue $ObjectToTest
        }
        
        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # Test if the object is empty
            [System.Boolean]$InputObjectIsEmpty = $this.TestObjectIsEmpty($this.ObjectToTest)
            # Determine the OutputObject
            $this.DetermineOutputObject($InputObjectIsEmpty)
        }
        
        # Add the End method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name End -Value {
            # Write the End message
            Write-Verbose ('___ END Function: [{0}] ParameterSetName: [{1}] Arguments: {2}' -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments)
        }

        ####################################################################################################

        # Add the TestObjectIsEmpty method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestObjectIsEmpty -Value { param([System.Object]$ObjectToTest)
            # If the object is null
            if ($this.TestObjectIsNull($ObjectToTest)) {
                # Return true
                $true
            } else {
                # Get the object type
                [System.String]$ObjectType = $this.GetObjectType($ObjectToTest)
                # Switch on the object type
                switch ($ObjectType) {
                    {$_ -in 'String'} { $this.TestStringIsEmpty($ObjectToTest) }
                    {$_ -in 'Array','Hashtable','PSCustomObject'} { $this.TestCollectionIsEmpty($ObjectToTest) }
                    # If the ObjectType is not defined, then return true
                    Default { Write-Host ('The ObjectType ({0}) is not yet defined in this function ({1}).' -f $ObjectType, $this.FunctionName) ; $true }
                }
            }
        }

        ####################################################################################################

        # Add the DetermineOutputObject method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name DetermineOutputObject -Value { param([System.Boolean]$InputObjectIsEmpty)
            # Determine the OutputObject based on the ParameterSetName
            $this.OutputObject = switch ($this.ParameterSetName) {
                'TestIfEmpty'       { $InputObjectIsEmpty }
                'TestIfPopulated'   { (-Not($InputObjectIsEmpty)) }
            }
        }

        ####################################################################################################

        # Add the GetObjectType method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetObjectType -Value { param([System.Object]$ObjectToTest)
            # Get the object type
            Write-Verbose 'GetObjectType: Getting the type of the object...'
            # If the object is an array
            [System.String]$ObjectType = if ($this.TestObjectIsArray($ObjectToTest)) {
                # Return Array
                'Array'
            } else {
                # Else return the TypeName
                [System.String]$TypeName = $ObjectToTest.GetType().Name
                Write-Verbose ('GetObjectType: The ObjectType is: {0}.' -f $TypeName)
                $TypeName
            }
            # Return the ObjectType
            $ObjectType
        }

        ####################################################################################################

        # Add the TestObjectIsNull method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestObjectIsNull -Value { param([System.Object]$ObjectToTest)
            # If the Object is null then return true, else return false
            Write-Verbose 'TestObjectIsNull: Testing if the Object is $null...'
            if ($null -eq $ObjectToTest) {
                Write-Verbose 'TestObjectIsNull: The Object is $null.'    
                $true
            } else {
                Write-Verbose 'TestObjectIsNull: The Object is not $null.' 
                $false
            }
        }

        # Add the TestObjectIsArray method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestObjectIsArray -Value { param([System.Object]$ObjectToTest)
            # If the Object is an array then return true, else return false
            Write-Verbose 'TestObjectIsArray: Testing if the Object is an array...'
            if (((($ObjectToTest.GetType()).BaseType).Name) -is 'Array') {
                Write-Verbose 'TestObjectIsArray: The Object is an array.'    
                $true
            } else {
                Write-Verbose 'TestObjectIsArray: The Object is not an array.' 
                $false
            }
        }

        # Add the TestStringIsEmpty method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestStringIsEmpty -Value { param([System.String]$StringToTest)
            # If the String is empty then return true, else return false
            Write-Verbose 'TestStringIsEmpty: Testing if the String is empty...'
            if ([string]::IsNullOrWhiteSpace($StringToTest)) {
                Write-Verbose 'TestStringIsEmpty: The String is empty.'    
                $true
            } else {
                Write-Verbose 'TestStringIsEmpty: The String is not empty.' 
                $false
            }
        }

        # Add the TestCollectionIsEmpty method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestCollectionIsEmpty -Value { param([System.Object]$CollectionToTest)
            # If the collection is empty
            Write-Verbose 'TestCollectionIsEmpty: Testing if the collection is empty...'
            if ($CollectionToTest.Count -eq 0) {
                #  Return true
                Write-Verbose 'TestCollectionIsEmpty: The collection is empty...'
                $true
            } else {
                #  Else return false
                Write-Verbose 'TestCollectionIsEmpty: The collection is not empty...'
                $false
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
        Return $Local:MainObject.OutputObject
        #endregion END
    }
}

