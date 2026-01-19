####################################################################################################
<#
.SYNOPSIS
    This function gets user information from the local system.
.DESCRIPTION
    This function is self-contained and does not refer to functions, variables or classes, that are in other files.
.EXAMPLE
    Get-UserInformation
.INPUTS
    [System.String]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    [System.String]
.NOTES
    Version         : 1.0
    Author          : Imraan Iotana
    Creation Date   : August 2024
    Last Updated    : August 2024
#>
####################################################################################################

function Get-UserInformation {
    [CmdletBinding()]
    param (
        # String for the user name
        [Parameter(Mandatory=$true,ParameterSetName='GetUserSIDFromUserName')]
        [System.String]
        $Username,
        
        # Switch for returning the user SID
        [Parameter(Mandatory=$true,ParameterSetName='GetUserSIDFromUserName')]
        [System.Management.Automation.SwitchParameter]
        $ReturnUserSID,
        
        # Switch for returning the Current user Name
        [Parameter(Mandatory=$true,ParameterSetName='GetCurrentUserName')]
        [System.Management.Automation.SwitchParameter]
        $CurrentUserName,
        
        # Switch for returning the Current user SID
        [Parameter(Mandatory=$true,ParameterSetName='GetCurrentUserSID')]
        [System.Management.Automation.SwitchParameter]
        $CurrentUserSID,
        
        # Switch for returning the LoggedOn user Name
        [Parameter(Mandatory=$true,ParameterSetName='GetLoggedOnUserName')]
        [System.Management.Automation.SwitchParameter]
        $LoggedOnUserName,
        
        # Switch for returning the LoggedOn user SID
        [Parameter(Mandatory=$true,ParameterSetName='GetLoggedOnUserSID')]
        [System.Management.Automation.SwitchParameter]
        $LoggedOnUserSID
    )

    begin {
        ####################################################################################################
        ### MAIN OBJECT ###

        # Set the main object
        [PSCustomObject]$Local:MainObject = @{
            # Function
            FunctionName        = [System.String]$MyInvocation.MyCommand
            FunctionArguments   = [System.String]$PSBoundParameters.GetEnumerator()
            ParameterSetName    = [System.String]$PSCmdlet.ParameterSetName
            FunctionCircumFix   = [System.String]'Function: [{0}] ParameterSetName: [{1}] Arguments: {2}'
            # Input
            Username            = $Username
            # Output
            OutputObject        = [System.String]::Empty
        }

        ####################################################################################################
        ### MAIN FUNCTION METHODS ###
        
        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Add the function details
            Add-Member -InputObject $this -NotePropertyName FunctionDetails -NotePropertyValue ($this.FunctionCircumFix -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments)
            # Write the Begin message
            Write-Verbose ('+++ BEGIN {0}' -f $this.FunctionDetails)
        }
    
        # Add the End method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name End -Value {
            # Write the End message
            Write-Verbose ('___ END {0}' -f $this.FunctionDetails)
        }

        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # Switch on the ParameterSetName
            $this.OutputObject = switch ($this.ParameterSetName) {
                'GetCurrentUserName'        { $this.GetCURRENTUserNameMethod() }
                'GetLoggedOnUserName'       { $this.GetOTHERLOGGEDONUserNameMethod() }
                'GetCurrentUserSID'         { $this.GetUserSIDFromUserNameMethod($this.GetCURRENTUserNameMethod()) }
                'GetLoggedOnUserSID'        { $this.GetUserSIDFromDOMAINUserNameMethod($this.GetOTHERLOGGEDONUserNameMethod()) }
                #'GetLoggedOnUserSID'        { $this.GetUserSIDFromUserNameMethod($this.GetOTHERLOGGEDONUserNameMethod()) }
                'GetUserSIDFromUserName'    { $this.GetUserSIDFromUserNameMethod($this.Username) }
            }
        }

        ####################################################################################################
        ### MAIN PROCESSING METHODS ###
    
        # Add the GetCURRENTUserNameMethod method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetCURRENTUserNameMethod -Value {
            # Write the message
            Write-Host 'Getting the username of the CurrentUser...' -ForegroundColor DarkGray
            try {
                # Get the username
                [System.String]$CurrentUserName = $Env:UserName
                # Write and return the result
                Write-Host ('The username was obtained: {0}' -f $CurrentUserName) -ForegroundColor DarkGray
                $CurrentUserName
            }
            catch {
                # Write and return the result
                Write-Host $Error[0].Exception.GetType().FullName
                Write-Host 'It was not possible to obtain the username.' -ForegroundColor Red
                $null
            }
        }
    
        # Add the GetCURRENTUserDomainMethod method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetCURRENTUserDomainMethod -Value {
            # Write the message
            Write-Host 'Getting the domain of the CurrentUser...' -ForegroundColor DarkGray
            try {
                # Get the domain
                [System.String]$CurrentUserDomain = $env:USERDOMAIN
                # Write and return the result
                Write-Host ('The domain was obtained: {0}' -f $CurrentUserDomain) -ForegroundColor DarkGray
                $CurrentUserDomain
            }
            catch {
                # Write and return the result
                Write-Host $Error[0].Exception.GetType().FullName
                Write-Host 'It was not possible to obtain the domain.' -ForegroundColor Red
                $null
            }
        }
    
        # Add the GetOTHERLOGGEDONUserNameMethod method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetOTHERLOGGEDONUserNameMethod -Value {
            # Write the message
            Write-Host 'Getting the username of the LoggedOnUser...' -ForegroundColor DarkGray
            <#try {
                # Get the username
                [System.String]$LoggedOnUserName = (Get-CimInstance -ClassName Win32_ComputerSystem).Username.Split('\')[1]
                # Write and return the result
                Write-Host ('The username was obtained: {0}' -f $LoggedOnUserName) -ForegroundColor DarkGray
                $LoggedOnUserName
            }#>
            #catch [System.Management.Automation.RuntimeException] {
            try {
                # Write and return the result
                #Write-Host 'It was not possible to obtain the username with Get-CimInstance, using the LastWriteTime method instead.' -ForegroundColor DarkGray
                Write-Host 'Getting the username of the LoggedOnUser...' -ForegroundColor DarkGray
                # Get the username
                [System.String]$ComputerName = $env:COMPUTERNAME
                [PSCustomObject[]]$Users = Get-ChildItem ('\\{0}\c$\Users' -f $ComputerName) | Sort-Object LastWriteTime -Descending | Select-Object Name, LastWriteTime
                # Remove the current user from the array
                [System.String]$CurrentUserName = $this.GetCURRENTUserNameMethod()
                Write-Host ('Subtracting the current user from the array...: {0}' -f $CurrentUserName) -ForegroundColor DarkGray
                [PSCustomObject[]]$NewUsers = $Users | Where-Object { $_.Name -ne $CurrentUserName }
                #$Users
                #Write-Host $NewUsers -ForegroundColor Cyan
                # Get the first user
                [System.String]$LoggedOnUserName = $NewUsers | Select-Object -First 1 -ExpandProperty Name
                # Write and return the result
                Write-Host ('The username was obtained: {0}' -f $LoggedOnUserName) -ForegroundColor DarkGray
                $LoggedOnUserName
            }
            catch {
                # Write and return the result
                Write-Host $Error[0].Exception.GetType().FullName
                Write-Host 'It was not possible to obtain the username of the LoggedOnUser.' -ForegroundColor Red
                $null
            }
        }
    
        # Add the GetUserSIDFromUserNameMethod method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetUserSIDFromUserNameMethod -Value { param([System.String]$Username)
            # If the string is empty, then return
            if ([System.String]::IsNullOrEmpty($Username)) { Write-Host 'The username string is empty. The user SID could not be obtained.' -ForegroundColor DarkGray }
            # Write the message
            Write-Host ('Getting user SID for user: {0}' -f $Username) -ForegroundColor DarkGray
            try {
                <# Get the user SID
                [System.String]$UserSID = Get-WmiObject win32_useraccount | Where-Object { $_.Name -eq $Username } | Select-Object -ExpandProperty sid
                # Write and return the result
                Write-Host ('The user SID was obtained: {0}' -f $UserSID) -ForegroundColor DarkGray
                $UserSID#>
                # Get the Identity object
                [System.Security.Principal.IdentityReference]$UserIdentityObject = New-Object System.Security.Principal.NTAccount($Username)
                Write-Host 'UserIdentityObject is:'
                $UserIdentityObject
                # Get the user SID
                [System.String]$UserSID = $UserIdentityObject.Translate([System.Security.Principal.SecurityIdentifier]).Value
                # Write and return the result
                Write-Host ('The user SID was obtained: {0}' -f $UserSID) -ForegroundColor DarkGray
                $UserSID
            }
            catch [System.Management.Automation.RuntimeException] {
                # Get the user SID
                [System.String]$UserSID = Get-WmiObject win32_useraccount | Where-Object { $_.Name -eq $Username } | Select-Object -ExpandProperty sid
                # Write and return the result
                Write-Host ('The user SID was obtained: {0}' -f $UserSID) -ForegroundColor DarkGray
                $UserSID
            }
            catch {
                # Write and return the result
                Write-Host $Error[0].Exception.GetType().FullName
                Write-Host 'It was not possible to obtain the user SID.' -ForegroundColor Red
                $null
            }
        }
    
        # Add the GetUserSIDFromDOMAINUserNameMethod method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetUserSIDFromDOMAINUserNameMethod -Value { param([System.String]$Username)
            # If the string is empty, then return
            if ([System.String]::IsNullOrEmpty($Username)) { Write-Host 'The username string is empty. The user SID could not be obtained.' -ForegroundColor DarkGray }
            # Write the message
            Write-Host ('Getting user SID for user: {0}' -f $Username) -ForegroundColor DarkGray
            try {
                Write-Host ('USING DOMAIN METHOD') -ForegroundColor Yellow
                # Get the domain
                [System.String]$CurrentUserDomain = $this.GetCURRENTUserDomainMethod()
                # Get the Identity object
                $objUser = New-Object System.Security.Principal.NTAccount($CurrentUserDomain,$Username)
                $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
                [System.String]$UserSID = $strSID.Value
                #[System.Security.Principal.IdentityReference]$UserIdentityObject = New-Object System.Security.Principal.NTAccount($Username)
                #Write-Host 'UserIdentityObject is:'
                #$UserIdentityObject
                # Get the user SID
                #[System.String]$UserSID = $UserIdentityObject.Translate([System.Security.Principal.SecurityIdentifier]).Value
                # Write and return the result
                Write-Host ('The user SID was obtained: {0}' -f $UserSID) -ForegroundColor DarkGray
                $UserSID
            }
            catch [System.Management.Automation.RuntimeException] {
                # Get the user SID
                [System.String]$UserSID = Get-WmiObject win32_useraccount | Where-Object { $_.Name -eq $Username } | Select-Object -ExpandProperty sid
                # Write and return the result
                Write-Host ('The user SID was obtained: {0}' -f $UserSID) -ForegroundColor DarkGray
                $UserSID
            }
            catch {
                # Write and return the result
                Write-Host $Error[0].Exception.GetType().FullName
                Write-Host 'It was not possible to obtain the user SID.' -ForegroundColor Red
                $null
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
        # Return the output
        $Local:MainObject.OutputObject
        #endregion END
    }
}

### END OF SCRIPT
####################################################################################################
