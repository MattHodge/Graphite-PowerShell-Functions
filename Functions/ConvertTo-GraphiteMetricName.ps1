Function ConvertTo-GraphiteMetricName
{
<#
    .Synopsis
        Converts a metrics into a one that is suitable for Graphite.

    .Description
        Converts a metrics into a one that is suitable for Graphite.

    .Parameter MetricToClean
        The metric to be cleaned.

    .Example
        PS> ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\Processor(_Total)\% Processor Time" -MetricReplacementHash $replacementHash
            myserver.production.net.Processor.Total.ProcessorTime

            Cleaning a Windows Performance Counter so its ready for Graphite and removing underscores.

    .Notes
        NAME:      ConvertTo-GraphiteMetricName
        AUTHOR:    Matthew Hodgkins
        WEBSITE:   http://www.hodgkins.net.au
#>
    param
    (
        [CmdletBinding()]
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [string]$MetricToClean,

        # An [System.Collections.Specialized.OrderedDictionary] with Key being what to replace, and Value being what to replace it with.
        [parameter(Mandatory = $false)]
        [System.Collections.Specialized.OrderedDictionary]$MetricReplacementHash
    )
     
    $cleanNameOfSample = $MetricToClean
        
    ForEach ($m in $MetricReplacementHash.GetEnumerator())
    {
        # For Renaming HostName
        if ($m.Key -eq '$env:COMPUTERNAME')
        {
            Write-Verbose "Going to use custom HostName"
            # Generate a GUID for the host name which we will then replace later. This needs to be done so the regex rules applied to the metric do not mess with the hostname the user requests. (Issue #37).
            $hostGuid = ([guid]::NewGuid()).ToString().Replace('-','')

            # Set the host name to the hostGuid
            $cleanNameOfSample = $cleanNameOfSample -replace "\\\\$($env:COMPUTERNAME)\\","\\$($hostGuid)\"
        }
        # For RegEx Matches
        elseif ($m.Value -cmatch '#{CAPTUREGROUP}')
        {
            Write-Verbose "Going to use custom RegEx Capture Group"
            # Stores the matching regex into $Matches
            $cleanNameOfSample -match $m.Name | Out-Null

            # Replaces the string the user provided - this #{CAPTUREGROUP} to $Matches[1]
            $replacementString = $m.Value -replace '#{CAPTUREGROUP}', $Matches[1]

            $cleanNameOfSample = $cleanNameOfSample -replace $m.Name, $replacementString
        }
        # For Simple Find and Replaces
        else
        {
            Write-Verbose "Replacing: $($m.Name) With : $($m.Value)"
            $cleanNameOfSample = $cleanNameOfSample -replace $m.Name, $m.Value
        }

        # Finish Renaming the HostName
        if ($m.Key -eq '$env:COMPUTERNAME')
        {
            Write-Verbose "Replacing hostGuid '$($hostGuid)' with requested Hostname '$($m.Value)'"
            $cleanNameOfSample = $cleanNameOfSample -replace $hostGuid,$m.Value
        }
    }
 
    return $cleanNameOfSample
}