Set-StrictMode -Version Latest
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# Determine The Path Of The XML Config File
$configPath = [string](Split-Path -Parent $MyInvocation.MyCommand.Definition) + '\StatsToGraphiteConfig.xml'

# Internal Functions
. $here\Functions\Internal.ps1

. $here\Functions\ConvertTo-GraphiteMetric.ps1
. $here\Functions\Send-BulkGraphiteMetrics.ps1
. $here\Functions\Send-GraphiteEvent.ps1
. $here\Functions\Send-GraphiteMetric.ps1
. $here\Functions\Start-SQLStatsToGraphite.ps1
. $here\Functions\Start-StatsToGraphite.ps1

$functionsToExport = @(
    'ConvertTo-GraphiteMetric',
    'Send-BulkGraphiteMetrics',
    'Send-GraphiteEvent',
    'Send-GraphiteMetric',
    'Start-SQLStatsToGraphite',
    'Start-StatsToGraphite'
)

Export-ModuleMember -Function $functionsToExport
