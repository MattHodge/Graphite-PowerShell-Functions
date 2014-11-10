function Send-BulkGraphiteMetrics
{
<#
    .Synopsis
        Sends several Graphite Metrics to a Carbon server with one request. Bulk requests save a lot of resources for Graphite server.

    .Description
        This function takes hashtable (MetricPath => MetricValue) and Unix timestamp and sends them to a Graphite server.

    .Parameter CarbonServer
        The Carbon server IP or address.

    .Parameter CarbonServerPort
        The Carbon server port. Default is 2003.

    .Parameter Metrics
        Hashtable (MetricPath => MetricValue).

    .Parameter UnixTime
        The the unix time stamp of the metrics being sent the Graphite Server.

    .Parameter DateTime
        The DateTime object of the metrics being sent the Graphite Server. This does a direct conversion to Unix time without accounting for Time Zones. If your PC time zone does not match your Graphite servers time zone the metric will appear on the incorrect time.

    .Example
        Send-BulkGraphiteMetrics -CarbonServer myserver.local -CarbonServerPort 2003 -Metrics @{"houston.servers.webserver01.cpu.processortime" = 54; "houston.servers.webserver02.cpu.processortime" = 43} -UnixTime 1391141202
        This sends the houston.servers.webserver0*.cpu.processortime metrics to the specified carbon server.

    .Example
        Send-BulkGraphiteMetrics -CarbonServer myserver.local -CarbonServerPort 2003 -Metrics @{"houston.servers.webserver01.cpu.processortime" = 54; "houston.servers.webserver02.cpu.processortime" = 43} -DateTime (Get-Date)
        This sends the houston.servers.webserver0*.cpu.processortime metrics to the specified carbon server.

    .Notes
        NAME:      Send-BulkGraphiteMetrics
        AUTHOR:    Alexey Kirpichnikov

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
        [hashtable]$Metrics,

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
        # Convert to a Unix time without any rounding
        $UnixTime = (Get-Date $DateTime -UFormat %s) -Replace ("[,\.]\d*", "")
    }

    # Create Send-To-Graphite Metric
    [string[]]$metricStrings = @()
    foreach ($key in $Metrics.Keys)
    {
        $metricStrings += $key + " " + $Metrics[$key] + " " + $UnixTime

        Write-Verbose ("Metric Received: " + $metricStrings[-1])
    }

    $sendMetricsParams = @{
        "CarbonServer" = $CarbonServer
        "CarbonServerPort" = $CarbonServerPort
        "Metrics" = $metricStrings
        "IsUdp" = $UDP
        "TestMode" = $TestMode
    }

    SendMetrics @sendMetricsParams
}