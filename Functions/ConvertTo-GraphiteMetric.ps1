Function ConvertTo-GraphiteMetric
{
<#
    .Synopsis
        Converts Windows PerfMon metrics into a metric name that is suitable for Graphite.

    .Description
        Converts Windows PerfMon metrics into a metric name that is suitable for a Graphite metric path.

    .Parameter MetricToClean
        The metric to be cleaned.

    .Parameter RemoveUnderscores
        Removes Underscores from the metric name

    .Parameter NicePhysicalDisks
        Makes the physical disk perf counters prettier

    .Parameter HostName
        Allows you to override the hostname of the metrics before sending. Default is not to override and use what the Windows Performance Counters provide.

    .Example
        PS> ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec"
            myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec

            Cleaning a Windows Performance Counter so its ready for Graphite.

    .Example
        PS> ConvertTo-GraphiteMetric -MetricToClean "\\myServer\Processor(_Total)\% Processor Time" -RemoveUnderscores
            myServer.Processor.Total.ProcessorTime

            Cleaning a Windows Performance Counter so its ready for Graphite and removing underscores.

    .Example
        PS> ConvertTo-GraphiteMetric -MetricToClean "\\myServer\Processor(_Total)\% Processor Time" -RemoveUnderscores -HostName myserver.production.net
            myserver.production.net.Processor.Total.ProcessorTime

            Cleaning a Windows Performance Counter so its ready for Graphite and removing underscores. Replacing HostName with custom name.

    .Notes
        NAME:      ConvertTo-GraphiteMetric
        AUTHOR:    Matthew Hodgkins
        WEBSITE:   http://www.hodgkins.net.au
#>
    param
    (
        [CmdletBinding()]
        [parameter(Mandatory = $true)]
        [string]$MetricToClean,

        [parameter(Mandatory = $false)]
        [switch]$RemoveUnderscores,

        [parameter(Mandatory = $false)]
        [switch]$NicePhysicalDisks,

        [parameter(Mandatory = $false)]
        [string]$HostName=$env:COMPUTERNAME
    )

    # If HostName is being overwritten
    if ($HostName -ne $env:COMPUTERNAME)
    {
        $MetricToClean = $MetricToClean -replace "\\\\$($env:COMPUTERNAME)\\","\\$($HostName)\"
    }

    # Removing Beginning Backslashes"
    $cleanNameOfSample = $MetricToClean -replace '^\\\\', ''

    # Replacing Backslashes After ServerName With dot"
    $cleanNameOfSample = $cleanNameOfSample -replace '\\\\', '.'

    # Removing Replacing Colon with Dot"
    $cleanNameOfSample = $cleanNameOfSample -replace ':', '.'

    # Changing Fwd Slash To Dash"
    $cleanNameOfSample = $cleanNameOfSample -replace '\/', '-'

    # Changing BackSlash To Dot"
    $cleanNameOfSample = $cleanNameOfSample -replace '\\', '.'

    # Changing Opening Round Bracket to Dot"
    $cleanNameOfSample = $cleanNameOfSample -replace '\(', '.'

    # Removing Closing Round Bracket to Dot"
    $cleanNameOfSample = $cleanNameOfSample -replace '\)', ''

    # Removing Square Bracket"
    $cleanNameOfSample = $cleanNameOfSample -replace '\]', ''

    # Removing Square Bracket"
    $cleanNameOfSample = $cleanNameOfSample -replace '\[', ''

    # Removing Percentage Sign"
    $cleanNameOfSample = $cleanNameOfSample -replace '\%', ''

    # Removing Spaces"
    $cleanNameOfSample = $cleanNameOfSample -replace '\s+', ''

    # Removing Double Dots"
    $cleanNameOfSample = $cleanNameOfSample -replace '\.\.', '.'

    if ($RemoveUnderscores)
    {
        Write-Verbose "Removing Underscores as the switch is enabled"
        $cleanNameOfSample = $cleanNameOfSample -replace '_', ''
    }

    if ($NicePhysicalDisks)
    {
        Write-Verbose "NicePhyiscalDisks switch is enabled"

        # Get Drive Letter
        $driveLetter = ([regex]'physicaldisk\.[0-9]+([a-zA-Z])').match($cleanNameOfSample).groups[1].value

        # Add -drive to the drive letter
        $cleanNameOfSample = $cleanNameOfSample -replace 'physicaldisk\.[0-9]+([a-zA-Z])', ('physicaldisk.' + $driveLetter + '-drive')

        # Get the new cleaned drive letter
        $niceDriveLetter = ([regex]'physicaldisk\.(.*)\.avg\.').match($cleanNameOfSample).groups[1].value

        # Remvoe the .avg. section
        $cleanNameOfSample = $cleanNameOfSample -replace 'physicaldisk\.(.*)\.avg\.', ('physicaldisk.' + $niceDriveLetter + '.')
    }

    Write-Output $cleanNameOfSample
}
