# Graphite PowerShell Functions

A group of PowerShell functions that allow you to send Windows Performance counters to a Graphite Server, all configurable from a simple XML file.

## Modifying the Configuration File

The configuration file is fairly self-explanatory, but here is a description for each of the values.

### Graphite Configuration Section

Configuration Name | Description
--- | ---
CarbonServer | The server name where Carbon is running. The Carbon daemon is usually running on the Graphite server.
CarbonServerPort | The port number for Carbon. Its default port number is 2003
MetricPath | The path of the metric you want to be sent to the server
MetricSendIntervalSeconds | The interval to send metrics to Carbon. I recommend 5 seconds or greater. The more metrics you are collecting the longer it takes to send them to the Graphite server. You can see how long it takes to send the metrics each time the loop runs by using running the **Start-StatsToGraphite** function and having *VerboseOutput* set to *True*.
TimeZoneOfGraphiteServer | Set this to the time zone of your Graphite server and the **Start-StatsToGraphite** function will convert the local time zone of the server to the time zone of the Graphite server. This is useful if you have servers in different time zones. To get a list of valid options run **Convert-TimeZone -ListTimeZones** and use the applicable ID.

### Performance Counters Configuration Section

This section lists the performance counters you want the machine to send to Graphite. You can get these from Performance Monitor (perfmon.exe). I have included some basic performance counters in the configuration file. The asterisk means all devices - this comes directly from the performance counters themselves and is not part of the functionality of the PowerShell Scripts.

Here are some other examples

* <Counter Name="\Web Service(YourIISWebSite)\Total Bytes Received"/>
* <Counter Name="\Web Service(YourIISWebSite)\Total Bytes Sent"/>

### Filtering Configuration Section

This section lists names you want to filter out of the Performance Counter list. This is useful when you want to use a wildcard in the performance counter, want to skip some of the returned counters. I have included *isatap* and *teredo tunneling* by default to filter out IPv6 interfaces. Remove all <MetricFilter> tags if you want no filtering.

### Logging Configuration Section
Configuration Name | Description
--- | ---
VerboseOutput | Will provide each of the metrics that were sent over to Carbon and the total execution time of the loop.
