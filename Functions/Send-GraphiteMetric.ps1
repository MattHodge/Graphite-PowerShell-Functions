function Send-GraphiteMetric
{
<#
    .Synopsis
        Sends Graphite Metrics to a Carbon server.

    .Description
        This function takes a metric, value and Unix timestamp and sends it to a Graphite server.

    .Parameter CarbonServer
        The Carbon server IP or address.

    .Parameter CarbonServerPort
        The Carbon server port. Default is 2003.

    .Parameter MetricPath
        The Graphite formatted metric path. (Must contain no spaces).

    .Parameter MetricValue
        The the value of the metric path you are sending.

    .Parameter UnixTime
        The the unix time stamp of the metric being sent the Graphite Server.

    .Parameter DateTime
        The DateTime object of the metric being sent the Graphite Server. This does a direct conversion to Unix time without accounting for Time Zones. If your PC time zone does not match your Graphite servers time zone the metric will appear on the incorrect time.

    .Example
        Send-GraphiteMetric -CarbonServer myserver.local -CarbonServerPort 2003 -MetricPath houston.servers.webserver01.cpu.processortime -MetricValue 54 -UnixTime 1391141202
        This sends the houston.servers.webserver01.cpu.processortime metric to the specified carbon server.

    .Example
        Send-GraphiteMetric -CarbonServer myserver.local -CarbonServerPort 2003 -MetricPath houston.servers.webserver01.cpu.processortime -MetricValue 54 -DateTime (Get-Date)
        This sends the houston.servers.webserver01.cpu.processortime metric to the specified carbon server.

    .Notes
        NAME:      Send-GraphiteMetric
        AUTHOR:    Matthew Hodgkins
        WEBSITE:   http://www.hodgkins.net.au

#>
    param
    (
        [CmdletBinding(DefaultParametersetName = 'Date Object')]
        [parameter(Mandatory = $true)]
        [string]$CarbonServer,

        [parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [int]$CarbonServerPort = 2003,

        [parameter(Mandatory = $true)]
        [string]$MetricPath,

        [parameter(Mandatory = $true)]
        [string]$MetricValue,

        [Parameter(Mandatory = $true,
                   ParameterSetName = 'Epoch / Unix Time')]
        [ValidateRange(1, 99999999999999)]
        [string]$UnixTime,

        [Parameter(Mandatory = $true,
                   ParameterSetName = 'Date Object')]
        [datetime]$DateTime,

        # Will Display what will be sent to Graphite but not actually send it
        [Parameter(Mandatory = $false)]
        [switch]$TestMode,

        # Sends the metrics over UDP instead of TCP
        [Parameter(Mandatory = $false)]
        [switch]$UDP
    )

    # If Received A DateTime Object - Convert To UnixTime
    if ($DateTime)
    {
        $utcDate = $DateTime.ToUniversalTime()

        # Convert to a Unix time without any rounding
        [uint64]$UnixTime = [double]::Parse((Get-Date -Date $utcDate -UFormat %s))
    }

    # Create Send-To-Graphite Metric
    $metric = $MetricPath + " " + $MetricValue + " " + $UnixTime

    Write-Verbose "Metric Received: $metric"

    $sendMetricsParams = @{
        "CarbonServer" = $CarbonServer
        "CarbonServerPort" = $CarbonServerPort
        "Metrics" = $metric
        "IsUdp" = $UDP
        "TestMode" = $TestMode
    }

    SendMetrics @sendMetricsParams
}
