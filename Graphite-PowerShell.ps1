# Determine The Path Of The XML Config File
$configPath = [string](Split-Path -Parent $MyInvocation.MyCommand.Definition) + '\StatsToGraphiteConfig.xml'

Function Start-StatsToGraphite
{
<#
    .Synopsis
        Starts the loop which sends Windows Performance Counters to Graphite.

    .Description
        Starts the loop which sends Windows Performance Counters to Graphite. Configuration is all done from the StatsToGraphiteConfig.xml file.
        
    .Parameter Verbose
        Provides Verbose output which is useful for troubleshooting

    .Example
        PS> Start-StatsToGraphite
        
        Will start the endless loop to send stats to Graphite

    .Example
        PS> Start-StatsToGraphite -Verbose
        
        Will start the endless loop to send stats to Graphite and provide Verbose output.
        
    .Notes
        NAME:      Start-StatsToGraphite
        AUTHOR:    Matthew Hodgkins
        WEBSITE:   http://www.hodgkins.net.au
#>
	[CmdletBinding()]
	param ()
	
	# Run The Load XML Config Function
	$Config = Import-XMLConfig -ConfigPath $configPath
	
	# Get Last Run Time
	$lastRunTime = [DateTime]::MinValue
	
	# Start Endless Loop
	While ($True)
	{
		# Loop until enough time has passed to run the process again.
		While ((Get-Date) - $lastRunTime -lt $Config.MetricTimeSpan)
		{
			Start-Sleep -Milliseconds 500
		}
		
		# Update the Last Run Time and Use To Track How Long Execution Took
		$lastRunTime = Get-Date
		
		# Take the Sample of the Counter
		$collections = Get-Counter -Counter $Config.Counters -SampleInterval 1 -MaxSamples 1
		
		# Filter the Output of the Counters
		$samples = $collections.CounterSamples
		
		# Verbose
		Write-Verbose "All Samples Collected"
		
		# Convert To The TimeZone of the Graphite Server
		$convertedTime = Convert-TimeZone -DateTime (Get-Date -Format s) -ToTimeZone $Config.TimeZoneOfGraphiteServer
		
		# Get the TargetTime Part of the Script
		$convertedTime = $convertedTime.TargetTime
		
		# Round Time to Nearest Time Period
		$convertedTime = $convertedTime.AddSeconds(- ($convertedTime.Second % $Config.MetricSendIntervalSeconds))
		
		# Loop Through All The Counters
		ForEach ($sample in $samples)
		{
			if ($Config.ShowOutput)
			{
				$samplePath = $sample.Path
				Write-Verbose "Sample Name: $samplePath"
			}
			
			if ($sample.Path -notmatch [regex]$Config.Filters)
			{
				# Run the sample path through the ConvertTo-GraphiteMetric function
				$cleanNameOfSample = ConvertTo-GraphiteMetric -MetricToClean $sample.Path -RemoveUnderscores -NicePhysicalDisks
				
				$DebugOut = 'Job Execution Time To Get to Clean Metrics: ' + ((Get-Date) - $lastRunTime).TotalSeconds + ' seconds'
				Write-Verbose $DebugOut
				
				# Build the full metric path
				$metricPath = $Config.MetricPath + '.' + $cleanNameOfSample
				
				# Send To Graphite Server
				
				# Use Verbose if Verbose output is enabled in the config file.
				if ($Config.ShowOutput)
				{
					Send-GraphiteMetric -CarbonServer $Config.CarbonServer -CarbonServerPort $Config.CarbonServerPort -MetricPath $metricPath -MetricValue $sample.Cookedvalue -DateTime $convertedTime -Verbose
				}
				
				# If config value is not set, don't run command with Verbose switch
				else
				{
					Send-GraphiteMetric -CarbonServer $Config.CarbonServer -CarbonServerPort $Config.CarbonServerPort -MetricPath $metricPath -MetricValue $sample.Cookedvalue -DateTime $convertedTime
				}
				
				$DebugOut = 'Job Execution Time To Get to Clean Metrics: ' + ((Get-Date) - $lastRunTime).TotalSeconds + ' seconds'
				Write-Verbose $DebugOut
			}
			
			else
			{
				Write-Verbose "Filtering out Sample Name: $samplePath as it matches something in the filters"
			}
		}
		
		# Reloads The Configuration File After the Loop so new counters can be added on the fly
		$Config = Import-XMLConfig -ConfigPath $configPath
		
		if ($Config.ShowOutput)
		{
			# Write To Console How Long Execution Took
			$VerboseOutPut = 'PerfMon Job Execution Time: ' + ((Get-Date) - $lastRunTime).TotalSeconds + ' seconds'
			Write-Output $VerboseOutPut
		}
	}
}

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
	
	# Run The Load XML Config Function
	$Config = Import-XMLConfig -ConfigPath $configPath
	
	# Doesn’t Run Unless there is SQL Servers in the config file
	if ($Config.MSSQLServers.Length -eq 0)
	{
		Write-Error "There are no SQL Servers in your configuration file. Please add some before running this CmdLet"
		break
	}
	
	# Check for SQLPS Module
	if (($listofSQLModules = Get-Module -List SQLPS).Length -eq 1)
	{
		# Load The SQL Module
		Import-Module SQLPS
	}
	# Check for the PS SQL SnapIn
	elseif ((Test-Path ($env:ProgramFiles + '\Microsoft SQL Server\100\Tools\Binn\Microsoft.SqlServer.Management.PSProvider.dll')) -or (Test-Path ($env:ProgramFiles + ' (x86)' + '\Microsoft SQL Server\100\Tools\Binn\Microsoft.SqlServer.Management.PSProvider.dll')))
	{
		# Load The SQL SnapIns
		Add-PSSnapin SqlServerCmdletSnapin100
		Add-PSSnapin SqlServerProviderSnapin100
	}
	# If No Snapin's Found end the function
	else
	{
		Write-Error "Unable to find any SQL CmdLets. Please install them and try again."
		# End the Function
		Break
	}
	# Get Last Run Time
	$lastRunTime = [DateTime]::MinValue
	
	# Start Endless Loop
	While ($True)
	{
		# Loop until enough time has passed to run the process again.
		While ((Get-Date) - $lastRunTime -lt $Config.MSSQLMetricTimeSpan)
		{
			Start-Sleep -Milliseconds 500
		}
		
		# Update the Last Run Time and Use To Track How Long Execution Took
		$lastRunTime = Get-Date
		
		# Convert To The TimeZone of the Graphite Server
		$convertedTime = Convert-TimeZone -DateTime (Get-Date -Format s) -ToTimeZone $Config.TimeZoneOfGraphiteServer
		
		# Get the TargetTime Part of the Script
		$convertedTime = $convertedTime.TargetTime
		
		# Round Time to Nearest Time Period
		$convertedTime = $convertedTime.AddSeconds(- ($convertedTime.Second % $Config.MSSQLMetricSendIntervalSeconds))
		
		# Loop through each SQL Server
		ForEach ($sqlServer in $Config.MSSQLServers)
		{
			Write-Verbose "Running through SQLServer $($sqlServer.ServerInstance)"
			# Loop through each query for the SQL server
			ForEach ($query in $sqlServer.Queries)
			{
				Write-Verbose "Current Query $($query.TSQL)"
				
				# Run the Invoke-SqlCmd Cmdlet with a username and password only if they are present in the config file
				if ((($sqlServer.Username).Length -eq 0) -or (($sqlServer.Password).Length -eq 0))
				{
					$sqlCmdParams = @{
						'ServerInstance' = $sqlServer.ServerInstance;
						'Database' = $query.Database;
						'Query' = $query.TSQL;
						'ConnectionTimeout' = $Config.MSSQLConnectTimeout;
						'QueryTimeout' = $Config.MSSQLQueryTimeout
					}
				}
				# Run SQL cmd using credentials
				else
				{
					$sqlCmdParams = @{
						'ServerInstance' = $sqlServer.ServerInstance;
						'Database' = $query.Database;
						'Query' = $query.TSQL;
						'ConnectionTimeout' = $Config.MSSQLConnectTimeout;
						'QueryTimeout' = $Config.MSSQLQueryTimeout;
						'Username' = $sqlServer.Username;
						'Password' = $sqlServer.Password
					}
				}
				
				# Run the SQL Command
				try
				{
					$sqlresult = Invoke-SQLCmd @sqlCmdParams
					
					# Build the MetricPath that will be used to send the metric to Graphite
					$metricPath = $Config.MSSQLMetricPath + '.' + $query.MetricName
					
					# Send-GraphiteMetric Command - Verbose and TestMode
					if ($TestMode)
					{
						$sendGraphiteCmdParams = @{
							CarbonServer = $Config.CarbonServer;
							CarbonServerPort = $Config.CarbonServerPort;
							MetricPath = $metricPath;
							DateTime = $convertedTime;
							MetricValue = $sqlresult[0];
							Verbose = $True;
							TestMode = $True;
						}
					}
					# Send-GraphiteMetric Command - Verbose
					elseif ($Config.ShowOutput)
					{
						$sendGraphiteCmdParams = @{
							CarbonServer = $Config.CarbonServer;
							CarbonServerPort = $Config.CarbonServerPort;
							MetricPath = $metricPath;
							MetricValue = $sqlresult[0];
							DateTime = $convertedTime;
							Verbose = $True;
						}
					}
					# Send-GraphiteMetric Command - Metrics Only
					else
					{
						$sendGraphiteCmdParams = @{
							CarbonServer = $Config.CarbonServer;
							CarbonServerPort = $Config.CarbonServerPort;
							MetricPath = $metricPath;
							MetricValue = $sqlresult[0];
							DateTime = $convertedTime;
						}
					}
					
					Send-GraphiteMetric @sendGraphiteCmdParams
					
					Write-Verbose ('Job Exceution Time: ' + ((Get-Date) - $lastRunTime).TotalSeconds + ' seconds')
				}
				catch
				{
					Write-Error "Caught an exception"
					Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
					Write-Error "Exception Message: $($_.Exception.Message)"
				}
			} #end ForEach Query
		} #end ForEach SQL Server
		
		
		if ($Config.ShowOutput)
		{
			# Write To Console How Long Execuption Took
			$VerboseOutPut = 'SQL Job Exceution Time: ' + ((Get-Date) - $lastRunTime).TotalSeconds + ' seconds'
			Write-Output $VerboseOutPut
		}
		
		# Reloads The Configuration File After the Loop so new queries can be added on the fly
		$Config = Import-XMLConfig -ConfigPath $configPath
	} #end While Loop
}

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
		[switch]$TestMode
	)
	
	# If Received A DateTime Object - Convert To UnixTime
	if ($DateTime)
	{
		# Convert to a Unix time without any rounding
		$UnixTime = (Get-Date $DateTime -UFormat %s) -Replace ("[,\.]\d*", "")
	}
	
	# Create Send-To-Graphite Metric
	$metric = $MetricPath + " " + $MetricValue + " " + $UnixTime
	
	Write-Verbose "Metric Received: $metric"
	
	# Do not send if TestMode enabled
	if (!($TestMode))
	{
		try
		{
			#Stream results to the Carbon server
			$socket = New-Object System.Net.Sockets.TCPClient
			$socket.connect($CarbonServer, $CarbonServerPort)
			$stream = $socket.GetStream()
			$writer = new-object System.IO.StreamWriter($stream)
			
			#Write out metric to the stream.
			$writer.WriteLine($metric)
			$writer.Flush() #Flush and write our metrics.
			$writer.Close()
			$stream.Close()
		}
		catch
		{
			Write-Error "Error sending metrics to the Graphite Server. Please check your configuration file"
		}
	}
}

function Send-GraphiteEvent
{
<#
    .Synopsis
        Sends an event to Graphite.

    .Description
        Sends an event to a Graphite server. Examples of events that are appropriate for this metric type include releases, commits, application exceptions or anything that represents a state change where you might wish to track the affected data. More information is available here: http://obfuscurity.com/2014/01/Graphite-Tip-A-Better-Way-to-Store-Events

    .Example
        PS> Send-GraphiteEvent -GraphiteURL "http://10.4.48.113:81/" -What "Windows Patch Deploy"
        
        Sends an event to Graphite.

    .Example
        PS> Send-GraphiteEvent -GraphiteURL "http://10.4.48.113:81/" -What "Website Deploy" -Tags "webdeploy, patches"
        
        Sends a web deploy event to Graphite with multiple tags.

    .Example
        PS> Send-GraphiteEvent -GraphiteURL "http://10.4.48.113:81/" -What "Website Deploy" -Tags "webdeploy" -Data "Deployed patch #4123 to the Web Server"
        
        Sends a web deploy event to Graphite with Tags and Data.
        
    .Notes
        NAME:      Send-GraphiteEvent
        AUTHOR:    Matthew Hodgkins
        WEBSITE:   http://www.hodgkins.net.au
#>
	[CmdletBinding()]
	param
	(
		[CmdletBinding()]
		# The URL of the Graphite Servers Web Interface. For example http://10.4.48.113:8080 or https://myGraphiteServer.local
		[Parameter(Mandatory = $true)]
		[ValidateNotNull()]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ $_ -match '^(http|https)\:\/\/.*' })]
		[string]$GraphiteURL,
		
		# The "What" or Topic for the Event
		[Parameter(Mandatory = $true)]
		[ValidateNotNull()]
		[ValidateNotNullOrEmpty()]
		[Alias("Topic", "Title", "Subject")]
		[string]$What,
		
		# A tag or multiple tags for the event. If you are using multiple tags, separated then with commas
		[Parameter(Mandatory = $false)]
		[ValidateNotNull()]
		[ValidateNotNullOrEmpty()]
		[string]$Tags,
		
		# The body of the event
		[Parameter(Mandatory = $false)]
		[ValidateNotNull()]
		[ValidateNotNullOrEmpty()]
		[Alias("Body")]
		[string]$Data
	)
	
	# Check for trailing slash
	if (!($GraphiteURL.Substring($GraphiteURL.Length - 1) -eq '/'))
	{
		$GraphiteURL = $GraphiteURL + '/'
	}
	
	# Construct Full URL to Events API
	$GraphiteURL = $GraphiteURL + '/events/'
	
	# Build an Object to hold the data from the Function
	$EventObject = New-Object PSObject -Property @{
		what = $What
	}
	
	# If there are tags
	if ($Tags)
	{
		Add-Member -NotePropertyName tags -NotePropertyValue $Tags -InputObject $EventObject
	}
	
	# If there is data
	if ($Data)
	{
		Add-Member -NotePropertyName data -NotePropertyValue $Data -InputObject $EventObject
	}
	
	$EventObject = $EventObject | ConvertTo-Json
	
	Write-Verbose "Json Object:"
	Write-Verbose $EventObject
	
	try
	{
		$result = Invoke-WebRequest -Uri $GraphiteURL -Body $EventObject -method Post -ContentType "application/json"
		Write-Verbose "Returned StatusCode: $($result.StatusCode)"
		Write-Verbose "Returned StatusDescription: $($result.StatusDescription)"
	}
	
	catch
	{
		Write-Error "Caught an exception"
		Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
		Write-Error "Exception Message: $($_.Exception.Message)"
	}
	
}

function Convert-TimeZone
{
    <#
        .Synopsis
           Coverts from a given time zone to the specified time zone.

        .Description
            Coverts from a given time zone to the specified time zone.
        
        .Parameter DateTime
            A DateTime object will be converted to the new time zone.
    
        .Parameter ToTimeZone    
            The name of the target time zone you wish to convert to. You can get the names by using the -ListTimeZones parameter.
        
        .Parameter ListTimeZones
            Lists all the time zones that can be used.
    
        .Example
            Convert-TimeZone -ListTimeZones

            Id                         : Dateline Standard Time
            DisplayName                : (UTC-12:00) International Date Line West
            StandardName               : Dateline Standard Time
            DaylightName               : Dateline Daylight Time
            BaseUtcOffset              : -12:00:00
            SupportsDaylightSavingTime : False

            Id                         : UTC-11
            DisplayName                : (UTC-11:00) Coordinated Universal Time-11
            StandardName               : UTC-11
            DaylightName               : UTC-11
            BaseUtcOffset              : -11:00:00
            SupportsDaylightSavingTime : False

            Lists available time zones to convert to.

        .Example
            Convert-TimeZone -DateTime (Get-Date) -ToTimeZone UTC
            
            Converts current time to UTC time.
                
        .Notes
            NAME:      Convert-TimeZone
            AUTHOR:    Matthew Hodgkins
            WEBSITE:   http://www.hodgkins.net.au

    #>
	
	param
	(
		[CmdletBinding(DefaultParametersetName = 'Convert Time Zone')]
		
		[Parameter(Mandatory = $true,
				   ParameterSetName = 'Convert Time Zone')]
		[ValidateNotNull()]
		[ValidateNotNullOrEmpty()]
		[datetime]$DateTime,
		
		[Parameter(Mandatory = $true,
				   ParameterSetName = 'Convert Time Zone')]
		[ValidateNotNull()]
		[ValidateNotNullOrEmpty()]
		[string]$ToTimeZone,
		
		[Parameter(Mandatory = $false,
				   ParameterSetName = 'List Time Zones')]
		[switch]$ListTimeZones
	)
	
	# Loading dll for Windows 2003 R2
	[void][System.Reflection.Assembly]::LoadWithPartialName('System.Core')
	
	# List TimeZones for the user
	if ($ListTimeZones)
	{
		[System.TimeZoneInfo]::GetSystemTimeZones()
	}
	
	# Run the Function
	else
	{
		$TimeZoneObject = [System.TimeZoneInfo]::GetSystemTimeZones() | Where-Object { $_.id -eq $ToTimeZone }
		
		$TargetZoneTime = [System.TimeZoneInfo]::ConvertTime($DateTime, $TimeZoneObject)
		
		$OutObject = New-Object -TypeName PSObject -Property @{
			LocalTime = $DateTime
			LocalTimeZone = $(([System.TimeZoneInfo]::LOCAL).id)
			TargetTime = $TargetZoneTime
			TargetTimeZone = $($TimeZoneObject.id)
		}
		
		Write-Output $OutObject
	}
}

Function Import-XMLConfig
{
<#
    .Synopsis
        Loads the XML Config File for Send-StatsToGraphite.

    .Description
        Loads the XML Config File for Send-StatsToGraphite.
        
    .Parameter ConfigPath
        Full path to the configuration XML file.
        
    .Example
        Import-XMLConfig -ConfigPath C:\Stats\Send-PowerShellGraphite.ps1
                
    .Notes
        NAME:      Convert-TimeZone
        AUTHOR:    Matthew Hodgkins
        WEBSITE:   http://www.hodgkins.net.au

#>
	[CmdletBinding()]
	Param
	(
		# Configuration File Path
		[Parameter(Mandatory = $true)]
		$ConfigPath
	)
	
	[hashtable]$Config = @{ }
	
	# Load Configuration File
	$xmlfile = [xml](Get-Content $configPath)
	
	#Set the Graphite carbon server location and port number
	$Config.CarbonServer = $xmlfile.Configuration.Graphite.CarbonServer
	$Config.CarbonServerPort = $xmlfile.Configuration.Graphite.CarbonServerPort
	
	#Get Metric Send Interval From Config
	[int]$Config.MetricSendIntervalSeconds = $xmlfile.Configuration.Graphite.MetricSendIntervalSeconds
	
	# Get the Timezone Of the Graphite Server
	$Config.TimeZoneOfGraphiteServer = $xmlfile.Configuration.Graphite.TimeZoneOfGraphiteServer
	
	# Convert Interval into TimeSpan
	$Config.MetricTimeSpan = [timespan]::FromSeconds($Config.MetricSendIntervalSeconds)
	
	# What is the metric path
	
	$Config.MetricPath = $xmlfile.Configuration.Graphite.MetricPath
	
	# Convert Value in Configuration File to Bool for showing Verbose Output
	[bool]$Config.ShowOutput = [System.Convert]::ToBoolean($xmlfile.Configuration.Logging.VerboseOutput)
	
	# Create the Performance Counters Array
	$Config.Counters = @()
	
	# Load each row from the configuration file into the counter array
	ForEach ($counter in $xmlfile.Configuration.PerformanceCounters.Counter)
	{
		$Config.Counters += $counter.Name
	}
	
	# Use the filters to create a RegEx string
	if ($xmlfile.Configuration.Filtering.MetricFilter)
	{
		# Load each row from the configuration file into the counter array
		ForEach ($MetricFilter in $xmlfile.Configuration.Filtering.MetricFilter)
		{
			$Config.Filters += $MetricFilter.Name + '|'
		}
		
		# Strip the Last Pipe From the filters string so regex can work against the string.
		$Config.Filters = $Config.Filters.Substring(0, $Config.Filters.Length - 1)
	}
	
	# If there are no filters, put in something that will never match so all the counters will be allowed through.
	else
	{
		$Config.Filters = 'nothingwillevermatchthishugestring'
	}
	
	# Below is for SQL Metrics
	$Config.MSSQLMetricPath = $xmlfile.Configuration.MSSQLMetics.MetricPath
	$Config.MSSQLMetricSendIntervalSeconds = $xmlfile.Configuration.MSSQLMetics.MetricSendIntervalSeconds
	$Config.MSSQLMetricTimeSpan = [timespan]::FromSeconds($Config.MSSQLMetricSendIntervalSeconds)
	[int]$Config.MSSQLConnectTimeout = $xmlfile.Configuration.MSSQLMetics.SQLConnectionTimeoutSeconds
	[int]$Config.MSSQLQueryTimeout = $xmlfile.Configuration.MSSQLMetics.SQLQueryTimeoutSeconds
	
	# Create the Performance Counters Array
	$Config.MSSQLServers = @()
	
	ForEach ($sqlServer in $xmlfile.Configuration.MSSQLMetics.SQLServers.SQLServer)
	{
		# Load each SQL Server into an array
		$Config.MSSQLServers += [pscustomobject]@{ ServerInstance = $sqlServer.ServerInstance; Username = $sqlServer.Username; Password = $sqlServer.Password; Queries = $sqlServer.Query }
	}
	
	Return $Config
}