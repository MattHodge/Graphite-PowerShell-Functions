<#
.Synopsis
   Format Windows Performance Counters into a TimeStamp, Name, Value format.
.DESCRIPTION
   Formats Microsoft.PowerShell.Commands.GetCounter.PerformanceCounterSampleSet into a standard format to be converted to a metric to send.
.EXAMPLE
   PS> Get-Counter -Counter '\memory\available mbytes' -SampleInterval 1 -MaxSamples 1 | Format-PerformanceCounter

   Formats the performance counter into a standard format.
#>
function Format-PerformanceCounter
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        # A Microsoft.PowerShell.Commands.GetCounter.PerformanceCounterSampleSet object to format.
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.Commands.GetCounter.PerformanceCounterSampleSet]$InputObject
    )

        return ($InputObject.CounterSamples | Select-Object @{Name="TimeStamp";Expression={$_."Timestamp"}},@{Name="Name";Expression={$_."Path"}},@{Name="Value";Expression={$_."CookedValue"}})
}