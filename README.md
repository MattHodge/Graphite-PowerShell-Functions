# Graphite PowerShell Functions

A group of PowerShell functions that allow you to send Windows Performance counters to a Graphite Server, all configurable from a simple XML file.

## Installation

1. Download the *Graphite-PowerShell.ps1* file and the *StatsToGraphiteConfig.xml* configuration file into the same directory, for example C:\GraphitePowerShell
2. Make sure the files are un-blocked by right clicking on them and going to properties
3. Modify *StatsToGraphiteConfig.xml* configuration file. Instructions [here](#config)
3. Open PowerShell and ensure you set your Execution Policy to allow scripts be run eg. `Set-ExecutionPolicy RemoteSigned`


### Modifying the Configuration File

The configuration file is fairly self-explanatory, but here is a description for each of the values.

#### <a name="config"></a>Graphite Configuration Section

Configuration Name | Description
--- | ---
CarbonServer | The server name where Carbon is running. The Carbon daemon is usually running on the Graphite server.
CarbonServerPort | The port number for Carbon. Its default port number is 2003
MetricPath | The path of the metric you want to be sent to the server
MetricSendIntervalSeconds | The interval to send metrics to Carbon. I recommend 5 seconds or greater. The more metrics you are collecting the longer it takes to send them to the Graphite server. You can see how long it takes to send the metrics each time the loop runs by using running the **Start-StatsToGraphite** function and having *VerboseOutput* set to *True*.
TimeZoneOfGraphiteServer | Set this to the time zone of your Graphite server and the **Start-StatsToGraphite** function will convert the local time zone of the server to the time zone of the Graphite server. This is useful if you have servers in different time zones. To get a list of valid options run **Convert-TimeZone -ListTimeZones** and use the applicable ID.

#### Performance Counters Configuration Section

This section lists the performance counters you want the machine to send to Graphite. You can get these from Performance Monitor (perfmon.exe). I have included some basic performance counters in the configuration file. Asterisks can be used as a wildcard.

Here are some other examples:

* `<Counter Name="\Web Service(YourIISWebSite)\Total Bytes Received"/>`
* `<Counter Name="\Web Service(YourIISWebSite)\Total Bytes Sent"/>`
* `<Counter Name="\ASP.NET Apps v4.0.30319(_lm_w3svc_1_Root_YourIISApp)\Request Wait Time"/>`

#### Filtering Configuration Section

This section lists names you want to filter out of the Performance Counter list. This is useful when you want to use a wildcard in the performance counter, want to skip some of the returned counters. I have included *isatap* and *teredo tunneling* by default to filter out IPv6 interfaces. Remove all <MetricFilter> tags if you want no filtering.

#### Logging Configuration Section
Configuration Name | Description
--- | ---
VerboseOutput | Will provide each of the metrics that were sent over to Carbon and the total execution time of the loop.
