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
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.Commands.GetCounter.PerformanceCounterSampleSet[]]$InputObject
    )


    Begin
    {
        $returnArray = @()
    }
    Process
    {
        ForEach ($c in $InputObject)
        {   
            Write-Verbose "Doing Counters For Time: $($counter.Timestamp)" 
            ForEach ($counterSample in $c.CounterSamples)
            {
            
                $metricObject = New-Object PSObject -Property @{            
                    TimeStamp = $c.Timestamp  
                    Name = $counterSample.Path         
                    Value = $counterSample.CookedValue                   
                }

                $returnArray += $metricObject

            }


        }
    }
    End
    {
        return $returnArray
    }
}
