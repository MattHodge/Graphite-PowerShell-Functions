# Graphite PowerShell Functions

A group of PowerShell functions that allow you to send Windows Performance counters to a Graphite Server, all configurable from a simple XML file.

## Modifying The Configuration File

The configuration file is fairly self explanitory, but here is a description for each of the values.

### Graphite Configuration Section

Configuration Name | Description
--- | ---
CarbonServer | The server name where Carbon is running. The Carbon daemon is usually running on the Graphite server.
CarbonServerPort | The port number for Carbon. Its default port number is 2003
MetricPath | The path of the metric you want to be sent to the server
MetricSendIntervalSeconds | The interval to send metrics to Carbon. I recommand 5 seconds or greater. The more metrics you are collecting the longer it takes to send them to the Graphite server.
