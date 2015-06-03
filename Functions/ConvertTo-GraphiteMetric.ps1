Function ConvertTo-GraphiteMetric
{
<#
    .Synopsis
        Converts an InputObject into metrics name that is suitable for sending to Graphite server via Carbon.

    .Description
        Send an Object or an Array of Objects with 3 Properties:
            - TimeStamp
            - Name
            - Value

        This Cmd-Let will convert this to a format which can be sent to a Graphite server via Carbon.

    .Parameter InputObject
        Array of Objects with 3 Properties: "TimeStamp", "Name", "Value"

    .Parameter MetricPrefix
        A Metric Prefix to attach to the front of the metrics.

    .Example
        Get-Counter -Counter '\memory\available mbytes' -SampleInterval 1 -MaxSamples 1 | Format-PerformanceCounter | ConvertTo-GraphiteMetric -MetricReplacementHash $config.MetricReplace

        myhostname.mem.availablembytes 4545 1433299042

        Cleaning a Windows Performance Counter so its ready for Graphite.

    .Example
        Get-Counter -Counter '\memory\available mbytes' -SampleInterval 1 -MaxSamples 1 | Format-PerformanceCounter | ConvertTo-GraphiteMetric -MetricReplacementHash $config.MetricReplace -MetricPrefix datacenter1.servers

        datacenter1.servers.myhostname.mem.availablembytes 4545 1433299042

        Cleaning a Windows Performance Counter so its ready for Graphite, and adding a MetricPrefix

    .Notes
        NAME:      ConvertTo-GraphiteMetric
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
        $InputObject,

        # Prefix to attach to the front of the metrics
        [Parameter(Mandatory=$false)]
        $MetricPrefix,

        # An [System.Collections.Specialized.OrderedDictionary] with Key being what to replace, and Value being what to replace it with.
        [parameter(Mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary]$MetricReplacementHash
    )


    Begin
    {
    }
    Process
    {
        ForEach ($i in $InputObject)
        {
            $fullMetricToReturn = $null

            # If MetricPrefix is being used
            if ($MetricPrefix)
            {
                $fullMetricToReturn += "$MetricPrefix."
            }
            
            # Convert the Name of the metic
            $metricName = $i.Name | ConvertTo-GraphiteMetricName -MetricReplacementHash $MetricReplacementHash

            $fullMetricToReturn += "$metricName "

            # Attach the Value of the Metric
            $fullMetricToReturn += "$($i.Value) "

            # Attach the UnixTime to the Metric
            $unixTime = $i.TimeStamp | ConvertTo-UTCUnixTime
            $fullMetricToReturn += $unixTime

            # Return the completed metric
            Write-Output $fullMetricToReturn
        }
    }
    End
    {
    }
}