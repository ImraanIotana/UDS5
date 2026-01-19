####################################################################################################
<#
.SYNOPSIS
    This function writes a line to the host in several colors.
.DESCRIPTION
    This function is self-contained and does not refer to functions, variables or classes, that are in other files.
.EXAMPLE
    Write-Line "Hello World!"
.EXAMPLE
    Write-Line "Hello World!" -Busy
.INPUTS
    [System.String]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    This function returns no stream output.
.NOTES
    Version         : 5.5.3
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : December 2025
#>
####################################################################################################

function Write-Line {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,Position=0,HelpMessage='The message that will be written to the host.')]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $Message,

        [Parameter(Mandatory=$false,HelpMessage='Type for deciding the colors.')]
        [ValidateSet('Busy','Success','Fail','Normal','Special','NoAction','SuccessNoAction','Seperation','DoubleSeperation','ValidationSuccess','ValidationFail')]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $Type
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        [System.String]$ApplicationID = $Global:DeploymentObject.ApplicationID

        # Create the Main Message Object
        [PSCustomObject]$MessageObject = @{
            InputMessage    = $Message
            MessageType     = $Type
            CallingFunction = [System.String]((Get-PSCallStack).Command[1]) # Get the name of the calling function
        }

        # Add the FullTimeStamp property
        $MessageObject | Add-Member -MemberType ScriptProperty FullTimeStamp -Value {
            [System.DateTime]$UTCTimeStamp  = [DateTime]::UtcNow
            [System.String]$LogDate         = $UTCTimeStamp.ToString('yyyy-MM-dd')
            [System.String]$LogTime         = $UTCTimeStamp.ToString('HH:mm:ss.fff')
            [System.String]$FullTimeStamp   = "$LogDate $LogTime"
            # Return the result
            $FullTimeStamp
        }

        # Add the FullMessage property
        $MessageObject | Add-Member -MemberType ScriptProperty FullMessage -Value {
            switch ($this.MessageType) {
                'NoAction'          {
                    'No action has been taken.'
                }
                'SuccessNoAction'          {
                    ("[$($this.FullTimeStamp)] [$($this.CallingFunction)]: The $($Global:DeploymentObject.Action)-process is considered successful. No action has been taken.")
                }
                'Seperation'        {
                    "[$($this.FullTimeStamp)] ----------------------------------------------------------------------------------------------------"
                }
                'DoubleSeperation'        {
                    "[$($this.FullTimeStamp)] ===================================================================================================="
                }
                'ValidationSuccess' {
                    ("[$($this.FullTimeStamp)] [$($this.CallingFunction)]: The validation is successful. The process will now start.")
                }
                'ValidationFail' {
                    ("[$($this.FullTimeStamp)] [$($this.CallingFunction)]: The validation failed. The process will NOT start.")
                }
                Default             {
                    if ($this.InputMessage.StartsWith('[')) {
                        "[$($this.FullTimeStamp)] $($this.InputMessage)"
                    } else {
                        ("[$($this.FullTimeStamp)] [$($this.CallingFunction)]: $($this.InputMessage)")
                    }
                }
            }
        }

        # Add the ForegroundColor property
        $MessageObject | Add-Member -MemberType ScriptProperty ForegroundColor -Value {
            switch ($this.MessageType) {
                'Busy'              { 'Yellow' }
                'Success'           { 'Green' }
                'Fail'              { 'White' }
                'Normal'            { 'White' }
                'Special'           { 'Cyan' }
                'SuccessNoAction'   { 'Green' }
                'Seperation'        { 'White' }
                'DoubleSeperation'  { 'White' }
                'ValidationFail'    { 'White' }
                Default             { 'DarkGray' }
            }
        }

        # Add the BackgroundColor property
        $MessageObject | Add-Member -MemberType ScriptProperty BackgroundColor -Value {
            switch ($this.MessageType) {
                'Fail'              { 'DarkRed' }
                'ValidationFail'    { 'DarkRed' }
                Default             { '' }
            }
        }


        # WRITE METHOD
        # Add the WriteMessage method
        $MessageObject | Add-Member -MemberType ScriptMethod WriteMessage -Value {
            # Switch on the BackgroundColor
            switch ([System.String]::IsNullOrEmpty($this.BackgroundColor)) {
                $false  { Write-Host $this.FullMessage -ForegroundColor $this.ForegroundColor -BackgroundColor $this.BackgroundColor }
                $true   { Write-Host $this.FullMessage -ForegroundColor $this.ForegroundColor }
            }
        }


        ####################################################################################################
        # EVENT VIEWER PROPERTIES

        # Add the EventViewerEntryType property
        $MessageObject | Add-Member -MemberType ScriptProperty EventViewerEntryType -Value {
            switch ($this.MessageType) {
                'ValidationFail'    { 'Error' }
                'Fail'              { 'Error' }
                Default             { 'Information' }
            }
        }

        # Add the EventViewerEventID property
        $MessageObject | Add-Member -MemberType ScriptProperty EventViewerEventID -Value {
            switch ($this.MessageType) {
                'ValidationFail'    { '5000' }
                'Fail'              { '6000' }
                'ValidationSuccess' { '7000' }
                'SuccessNoAction'   { '8000' }
                'Success'           { '9000' }
                Default             { '1000' }
            }
        }

        # WRITE EVENTVIEWER METHOD
        # Add the WriteEventViewerMessage method
        $MessageObject | Add-Member -MemberType ScriptMethod WriteEventViewerMessage -Value {
            # Write the Event Viewer Log entry
            Write-EventLog -LogName "Application Installation/$ApplicationID" -Source $ApplicationID -EntryType $this.EventViewerEntryType -EventId $this.EventViewerEventID -Message $this.FullMessage
        }

        ####################################################################################################
    }
    
    process {
        # Write the message
        $MessageObject.WriteMessage()
        #$MessageObject.WriteEventViewerMessage()
    }
    
    end {
    }
}

### END OF FUNCTION
####################################################################################################
