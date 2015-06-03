<#
.Synopsis
   Converts a DateTime object into UTC Unix Time.
.DESCRIPTION
   Converts a DateTime object into UTC Unix Time  (Epoch Time).
.EXAMPLE
   Get-Date | ConvertTo-UTCUnixTime 
   
   Converts a date to Unix Time
#>
function ConvertTo-UTCUnixTime
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [DateTime]
        $DateTime
    )

    $utcDate = $DateTime.ToUniversalTime()
        
    # Convert to a Unix time without any rounding
    [uint64]$UnixTime = [double]::Parse((Get-Date -Date $utcDate -UFormat %s))

    return $UnixTime
}