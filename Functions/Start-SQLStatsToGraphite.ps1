Function Start-SQLStatsToGraphite
{
<#
    .Synopsis
        Starts a loop which sends the result of SQL Server queries to Graphite.

    .Description
        Starts a loop which sends the result of SQL queries defined in the configuration file to Graphite. Configuration is all done from the StatsToGraphiteConfig.xml file. The specified SQL commands must return a single row containing a number.

        This function requires the Microsoft SQL PowerShell Modules/SnapIns. The easiest way to get these on your server is to download them from the SQL 2012 R2 Feature Pack. You will need to grab the following:
        - Microsoft® SQL Server® 2012 Shared Management Object
        - Microsoft® System CLR Types for Microsoft® SQL Server® 2012
        - Microsoft® Windows PowerShell Extensions for Microsoft® SQL Server® 2012

    .Parameter Verbose
        Provides Verbose output which is useful for troubleshooting

    .Parameter TestMode
        Result will be collected from SQL and the metric that would be sent to Graphite is shown, without sending the metric on to Graphite.

    .Example
        PS> Start-SQLStatsToGraphite

        Will start the endless loop to send the result of the SQL queries to Graphite.

    .Example
        PS> Start-SQLStatsToGraphite -Verbose

        Will start the endless loop to send the result of the SQL queries to Graphite and provide Verbose output.

    .Example
        PS> Start-SQLStatsToGraphite -TestMode

        Results will be collected from SQL but they will not be sent over to Graphite.

    .Notes
        NAME:      Start-SQLStatsToGraphite
        AUTHOR:    Matthew Hodgkins
        WEBSITE:   http://www.hodgkins.net.au
#>
    [CmdletBinding()]
    Param
    (
        # Enable Test Mode. Metrics will not be sent to Graphite
        [Parameter(Mandatory = $false)]
        [switch]$TestMode
    )

    $PSBoundParameters['ExcludePerfCounters'] = $true
    $PSBoundParameters['SqlMetrics'] = $true

    Start-StatsToGraphite @PSBoundParameters
}