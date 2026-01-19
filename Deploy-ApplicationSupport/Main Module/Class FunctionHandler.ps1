####################################################################################################
<#
.SYNOPSIS
    This class contains properties and methods to help with a function.
.DESCRIPTION
    This function is part of the Iotana IT Assistant. However this class is self-contained and does not refer to functions and variables, that are in other files.
.EXAMPLE
    $MyNewFunctionHelper = [FunctionHandler]::New([System.String]$MyInvocation.MyCommand,[System.String]$PSBoundParameters.GetEnumerator(),[System.String]$PSCmdlet.ParameterSetName)
.INPUTS
    This class has 2 mandatory input parameters:
    FunctionName (String)       : The name of the calling/creating function.
    FunctionArguments (String)  : The arguments of the calling/creating function.
    ParameterSetName (String)   : The ParameterSetName of the calling/creating function.
.OUTPUTS
    This class has the following output:
    The method WriteBeginMessageVerbose writes the start message verbose, but returns no output.
    The method WriteEndMessageVerbose writes the end message verbose, but returns no output.
.NOTES
    Version         : 1.0
    Author          : Imraan Noormohamed
    Creation Date   : July 2023
    Last Updated    : July 2023
#>
####################################################################################################

class FunctionHandler {

    # INPUT PROPERTIES
    [System.String]$FunctionName
    [System.String]$FunctionArguments
    [System.String]$ParameterSetName

    # STATIC PROPERTIES
    [System.String]$GlobalRootfolder = $Global:DeploymentObject.Rootfolder

    # INITIALIZATION
    FunctionHandler([System.String]$FunctionName,[System.String]$FunctionArguments,[System.String]$ParameterSetName){
        # Set the Input Properties
        $this.FunctionName      = $FunctionName
        $this.FunctionArguments = $FunctionArguments
        $this.ParameterSetName  = $ParameterSetName
    }

    # METHODS

    ####################################################################################################

    # PUBLIC METHOD WriteBeginMessage
    [void]WriteBeginMessage(){ Write-Verbose ('+++ BEGIN: Function ({0}) Arguments: {1}' -f $this.FunctionName, $this.FunctionArguments) }

    # PUBLIC METHOD WriteEndMessage
    [void]WriteEndMessage(){ Write-Verbose ('___ END: Function ({0}) Arguments: {1}' -f $this.FunctionName, $this.FunctionArguments) }

    # PUBLIC METHOD WriteValidatingInputMessage
    [void]WriteValidatingInputMessage(){ Write-Verbose ('{0}: Validating the Input...' -f $this.FunctionName) }

    # PUBLIC METHOD WriteNoInputValidationMessage
    [void]WriteNoInputValidationMessage(){ Write-Verbose ('{0}: This function has no validation.' -f $this.FunctionName) }

    # PUBLIC METHOD WriteValidationSuccessMessage
    [void]WriteValidationSuccessMessage(){ Write-Host ('{0}: The validation was successful. The Process method will now start.' -f $this.FunctionName) }

    # PUBLIC METHOD WriteValidationFailMessage
    [void]WriteValidationFailMessage(){ Write-Host ('{0}: The validation was NOT successful. The Process method will not start.' -f $this.FunctionName) -ForegroundColor Red }

    ####################################################################################################

    # PUBLIC METHOD StringIsEmpty
    [System.Boolean]StringIsEmpty([System.String]$StringToTest) {
        # Write the message
        Write-Verbose ('StringIsEmpty (FunctionHandler): Testing if the string is empty... ({0})' -f $StringToTest)
        # Test if the string is empty        
        [System.Boolean]$StringIsEmpty = [string]::IsNullOrWhiteSpace($StringToTest)
        # Write the result
        if ($StringIsEmpty) { Write-Verbose 'StringIsEmpty (FunctionHandler): The string is empty.' } else { Write-Verbose 'StringIsEmpty (FunctionHandler): The string is not empty.' }
        # Return the result
        Return $StringIsEmpty
    }
    
    # PUBLIC METHOD StringIsPopulated
    [System.Boolean]StringIsPopulated([System.String]$StringToTest) {
        # Write the message
        Write-Verbose ('StringIsPopulated (FunctionHandler): Testing if the string is populated... ({0})' -f $StringToTest)
        # Test if the string is populated        
        [System.Boolean]$StringIsPopulated = (-Not($this.StringIsEmpty($StringToTest)))
        # Write the result
        if ($StringIsPopulated) { Write-Verbose 'StringIsPopulated (FunctionHandler): The string is populated.' } else { Write-Verbose 'StringIsPopulated: The string is not populated.' }
        # Return the result
        Return $StringIsPopulated
    }
    
    # PUBLIC METHOD CollectionIsPopulated
    [System.Boolean]CollectionIsPopulated([System.Object[]]$CollectionToTest) {
        # Write the message
        Write-Verbose ('CollectionIsPopulated (FunctionHandler): Testing if the collection is populated... ({0})' -f $CollectionToTest)
        # Test if the collection is populated
        [System.Boolean]$CollectionIsPopulated = ($CollectionToTest.Count -gt 0)
        # Write the result
        if ($CollectionIsPopulated) { Write-Verbose 'CollectionIsPopulated (FunctionHandler): The collection is populated.' } else { Write-Verbose 'CollectionIsPopulated (FunctionHandler): The collection is not populated.' }
        # Return the result
        Return $CollectionIsPopulated
    }

    ####################################################################################################

    # PUBLIC METHOD GetFilePath WITHOUT PATH
    [System.String]GetFilePath([System.String]$FileName) {
        # Call the GetFilePath method with the Global Rootfolder
        Return ($this.GetFilePath($FileName, $this.GlobalRootfolder))
    }

    # PUBLIC METHOD GetFilePath WITH PATH
    [System.String]GetFilePath([System.String]$FileName,[System.String]$Path) {
        # Write the message
        Write-Host ('GetFilePath (FunctionHandler): Searching for the file ({0}) in the folder ({1}) and all subfolders...' -f $FileName, $Path)
        # Search the file
        [System.String]$FilePath = (Get-ChildItem -Path $Path -Recurse -Filter $FileName -ErrorAction SilentlyContinue).FullName
        # If the file was NOT found
        if ($this.StringIsEmpty($FilePath)) {
            # Write the error
            Write-Host ('GetFilePath (FunctionHandler): The file ({0}) was NOT found in the folder ({1}) or any subfolders.' -f $FileName, $Path) -ForegroundColor Red
        } else {
            # Write the message
            Write-Host ('GetFilePath (FunctionHandler): The file was found. The full path is: ({0})' -f $FilePath)
        }
        # Return the file path
        Return $FilePath
    }

    ####################################################################################################

    # PUBLIC METHOD GetLoggedOnUserName
    [System.String]GetLoggedOnUserName() {
        # Write the GettingUserName message
        Write-Host 'Getting username of currently logged in user...'
        try {
            # Get the username
            [System.String]$LoggedOnUserName = (Get-CimInstance -ClassName Win32_ComputerSystem).Username.Split('\')[1]
            # Write and return the result
            Write-Host ('The username was obtained: {0}' -f $LoggedOnUserName)
            Return $LoggedOnUserName
        }
        catch {
            # Write and return the result
            Write-Host 'It was not possible to obtain the username.' -ForegroundColor Red
            Return $null
        }
    }

    ####################################################################################################

    # PUBLIC METHOD Write WITHOUT COLOR
    [void]Write([System.Object]$InputObject) {
        # Set the colors
        [System.Collections.Hashtable]$WriteColors = @{ ForegroundColor = 'Black' ; BackgroundColor = 'Yellow' }
        # Call the private write method
        $this.Write($InputObject, $WriteColors)
    }

    # PUBLIC METHOD Write WITH COLOR
    [void]Write([System.Object]$InputObject, [System.ConsoleColor]$Color) {
        # Set the colors
        [System.Collections.Hashtable]$WriteColors = @{ ForegroundColor = $Color ; BackgroundColor = 'Black' }
        # Call the private write method
        $this.Write($InputObject, $WriteColors)
    }

    # PRIVATE METHOD Write
    [void]Write([System.Object]$InputObject, [System.Collections.Hashtable]$Colors) {
        # Set the fixes
        [System.Collections.Hashtable]$Fixes = @{
            MessageFix  = 'The object of the type ({0}) has the value: ({1})'
            HashFix     = 'The object of the type ({0}) has the following values:'
            ErrorFix    = 'The object of the type ({0}) is not defined.'
        }
        # Get the type of the object
        [System.String]$ObjectType = $InputObject.GetType().Name
        # Perform the Write action
        switch ($ObjectType) {
            {$_ -in 'Hashtable','PSCustomObject'}  {
                # Write the Hashtable or PSCustomObject to the host
                Write-Host ($Fixes.HashFix -f $ObjectType) @Colors
                Write-Host ($InputObject | Format-List | Out-String) @Colors
            }
            {$_ -in 'String','Int32','Boolean'} {
                # Write the String/Int/Boolean to the host
                Write-Host ($Fixes.MessageFix -f $ObjectType, $InputObject) @Colors
            }
            {$_ -in 'Object[]'}  {
                # Write the Array to the host
                Write-Host ($Fixes.MessageFix -f $ObjectType, [System.String]$InputObject) @Colors
            }
            Default {
                # Write the Error message to the host
                Write-Host ($Fixes.ErrorFix -f $ObjectType) @Colors
            }
        }
    }

    ####################################################################################################

    # PUBLIC METHOD TestFileIsSigned
    [System.Boolean]TestFileIsSigned([System.String]$FilePath) {
        try {
            # Write the message
            Write-Host ('TestFileIsSigned (FunctionHandler): Testing if the file has a Digital Signature... ({0})' -f $FilePath)
            # Get the signing status of the file
            [System.String]$SigningStatus = (Get-AuthenticodeSignature $FilePath).Status
            # If the file is signed
            if ($SigningStatus -eq $this.SignedStatus) {
                # Write the message
                Write-Host ('TestFileIsSigned (FunctionHandler): The file is signed. ({0})' -f $FilePath)
                # Return true
                Return $true
            } else {
                # Write the message
                Write-Host ('TestFileIsSigned (FunctionHandler): The file is NOT signed. ({0})' -f $FilePath)
                # Return false
                Return $false
            }
        }
        catch {
            # Write the error
            $Error[0]
            # Return null
            Return $null
        }
    }

    ####################################################################################################
    
}

