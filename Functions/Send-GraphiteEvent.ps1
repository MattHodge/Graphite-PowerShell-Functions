function Send-GraphiteEvent
{
<#
    .Synopsis
        Sends an event to Graphite.

    .Description
        Sends an event to a Graphite server. Examples of events that are appropriate for this metric type include releases, commits, application exceptions or anything that represents a state change where you might wish to track the affected data. More information is available here: http://obfuscurity.com/2014/01/Graphite-Tip-A-Better-Way-to-Store-Events

    .Example
        PS> Send-GraphiteEvent -GraphiteURL "http://10.4.48.113:81/" -What "Windows Patch Deploy"

        Sends an event to Graphite.

    .Example
        PS> Send-GraphiteEvent -GraphiteURL "http://10.4.48.113:81/" -What "Website Deploy" -Tags "webdeploy, patches"

        Sends a web deploy event to Graphite with multiple tags.

    .Example
        PS> Send-GraphiteEvent -GraphiteURL "http://10.4.48.113:81/" -What "Website Deploy" -Tags "webdeploy" -Data "Deployed patch #4123 to the Web Server"

        Sends a web deploy event to Graphite with Tags and Data.

    .Notes
        NAME:      Send-GraphiteEvent
        AUTHOR:    Matthew Hodgkins
        WEBSITE:   http://www.hodgkins.net.au
#>
    [CmdletBinding()]
    param
    (
        [CmdletBinding()]
        # The URL of the Graphite Servers Web Interface. For example http://10.4.48.113:8080 or https://myGraphiteServer.local
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_ -match '^(http|https)\:\/\/.*' })]
        [string]$GraphiteURL,

        # The "What" or Topic for the Event
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Topic", "Title", "Subject")]
        [string]$What,

        # A tag or multiple tags for the event. If you are using multiple tags, separated then with commas
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Tags,

        # The body of the event
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Body")]
        [string]$Data
    )

    # Check for trailing slash
    if (!($GraphiteURL.Substring($GraphiteURL.Length - 1) -eq '/'))
    {
        $GraphiteURL = $GraphiteURL + '/'
    }

    # Construct Full URL to Events API
    $GraphiteURL = $GraphiteURL + '/events/'

    # Build an Object to hold the data from the Function
    $EventObject = New-Object PSObject -Property @{
        what = $What
    }

    # If there are tags
    if ($Tags)
    {
        Add-Member -NotePropertyName tags -NotePropertyValue $Tags -InputObject $EventObject
    }

    # If there is data
    if ($Data)
    {
        Add-Member -NotePropertyName data -NotePropertyValue $Data -InputObject $EventObject
    }

    $EventObject = $EventObject | ConvertTo-Json

    Write-Verbose "Json Object:"
    Write-Verbose $EventObject

    try
    {
        $result = Invoke-WebRequest -Uri $GraphiteURL -Body $EventObject -method Post -ContentType "application/json"
        Write-Verbose "Returned StatusCode: $($result.StatusCode)"
        Write-Verbose "Returned StatusDescription: $($result.StatusDescription)"
    }

    catch
    {
        $exceptionText = GetPrettyProblem $_
        throw "An error occurred trying to post data to Graphite. $exceptionText"
    }

}