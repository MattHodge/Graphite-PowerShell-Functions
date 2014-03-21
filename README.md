# Graphite PowerShell Functions

A group of PowerShell functions that allow you to send Windows Performance counters to a Graphite Server, all configurable from a simple XML file.

More details at [http://www.hodgkins.net.au/mswindows/using-powershell-to-send-metrics-graphite/](http://www.hodgkins.net.au/mswindows/using-powershell-to-send-metrics-graphite/)

## Features

* Sends Stats to Graphite's Carbon daemon using UDP
* Will convert time zones. If your the server you want the metrics sent from is in a different time zone than your Graphite server, the script will convert the time so metrics come in with a time that matches the Graphite server.
* All configuration can be done in XML file
* Reloads the XML file automatically, so if more counters are added, next send interval, the script will pick up and changes or additional counters you added and start sending metrics for them to Graphite
* Additonal functions are exposed that allow you to send data to Graphite from PowerShell easily. [Here](#functions) is a list of included functions.
* Can be run as a service

## Installation

1. Download the *Graphite-PowerShell.ps1* file and the *StatsToGraphiteConfig.xml* configuration file into the same directory, for example *C:\GraphitePowerShell*
2. Make sure the files are un-blocked by right clicking on them and going to properties.
3. Modify *StatsToGraphiteConfig.xml* configuration file. Instructions [here](#config).
4. Open PowerShell and ensure you set your Execution Policy to allow scripts be run, for example `Set-ExecutionPolicy RemoteSigned`.

## Usage

1. In PowerShell, enter the directory the you downloaded the script, and dot source it `. .\Graphite-PowerShell.ps1`
2. Start the script by using the function `Start-StatsToGraphite`. If you want Verbose detailed use `Start-StatsToGraphite -Verbose`.

You may need to run the PowerShell instance with Administrative rights depending on the performace counters you want to access. This is due to the scripts use of the `Get-Counter` CmdLet. 

From the [Get-Counter help page on TechNet](http://technet.microsoft.com/library/963e9e51-4232-4ccf-881d-c2048ff35c2a(v=wps.630).aspx):

> Performance counters are often protected by access control lists (ACLs). To get all available performance counters, open Windows PowerShell with the "Run as administrator" option.

This is what the verbose output looks like when it is turned on in the XML configuration file.

![alt text](http://i.imgur.com/G3pwnhf.jpg "Verbse")

That is all there is too getting your metrics into Graphite.

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

This section lists the performance counters you want the machine to send to Graphite. You can get these from Performance Monitor (perfmon.exe) or by using the command `typeperf -qx` in a command prompt.

I have included some basic performance counters in the configuration file. Asterisks can be used as a wildcard.

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

## Installing as a Service

Once you have edited the configuration file and verifed it is functioning correctly by running `Start-StatsToGraphite` in an interactive PowerShell session, you might want to install the script as a service.

The easiest way to achive this is using NSSM - the Non-Sucking Service Manager.

1. Download nssm from [nssm.cc](http://nssm.cc)
2. Open up an Administrative command prompt and run `nssm install GraphitePowerShell`. (You can call the service whatever you want).
3. A dialog will pop up allowing you to enter in settings for the new service. The table below contains the settings.

![alt text](http://i.imgur.com/xkiRZgu.jpg "NSSM Dialog")

4. Click *Install Service*
5. Make sure the service is started and it is set to Automatic
6. Check your Graphite server and make sure the metrics are coming in

Setting Name | Value
--- | ---
Path | C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
Startup Directory | C:\GraphitePowerShell
Options | -command "& { . C:\GraphitePowerShell\Graphite-PowerShell.ps1; Start-StatsToGraphite }"

If you want to remove the service, read the NSSM documentation [http://nssm.cc/commands](http://nssm.cc/commands).

## <a name="functions">Included Functions

A handful of functions used with the script, which are exposed and available to use in an ad-hoc manner.

For full help for these functions run the PowerShell command `Get-Help | <Function Name>`

Function Name | Description
--- | ---
Start-StatsToGraphite | The main function. This is an endless loop which will send metrics to Graphite. 
ConvertTo-GraphiteMetric | Takes the Windows Performance counter name and coverts it to something that Graphite can use.
Send-GraphiteMetric | Allows you to send metrics to Graphite in an ad-hoc manner.
Convert-TimeZone | Converts from one time zone to another.
Import-XMLConfig | Loads the XML Configuration file. Not really useful out side of the script.
