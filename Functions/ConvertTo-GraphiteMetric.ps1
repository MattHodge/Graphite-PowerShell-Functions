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

    .Example
        PS> ConvertTo-GraphiteMetric -MetricToClean "\Processor(_Total)\% Processor Time"
            .Processor._Total.ProcessorTime

    .Example
        PS> ConvertTo-GraphiteMetric -MetricToClean "\Processor(_Total)\% Processor Time" -RemoveUnderscores
            .Processor.Total.ProcessorTime

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
        [switch]$NicePhysicalDisks
    )

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
        $driveLetter = ([regex]'physicaldisk\.\d([a-zA-Z])').match($cleanNameOfSample).groups[1].value

        # Add -drive to the drive letter
        $cleanNameOfSample = $cleanNameOfSample -replace 'physicaldisk\.\d([a-zA-Z])', ('physicaldisk.' + $driveLetter + '-drive')

        # Get the new cleaned drive letter
        $niceDriveLetter = ([regex]'physicaldisk\.(.*)\.avg\.').match($cleanNameOfSample).groups[1].value

        # Remvoe the .avg. section
        $cleanNameOfSample = $cleanNameOfSample -replace 'physicaldisk\.(.*)\.avg\.', ('physicaldisk.' + $niceDriveLetter + '.')
    }

    Write-Output $cleanNameOfSample
}