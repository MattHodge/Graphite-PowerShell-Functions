# Graphite PowerShell Functions

A group of PowerShell functions that allow you to send Windows Performance counters to a Graphite Server, all configurable from a simple XML file.

This work is all from MattHodge Repo https://github.com/MattHodge/Graphite-PowerShell-Functions but with some small modification by myself to now allow a service status to be sent. If the service is up it sends a 1, if it is down it sends a 0. 

[![GitHub Version]](https://github.com/MarkDordoy/Graphite-PowerShell-Functions/releases)

More details at [http://www.hodgkins.net.au/mswindows/using-powershell-to-send-metrics-graphite/](http://www.hodgkins.net.au/mswindows/using-powershell-to-send-metrics-graphite/)

## Features

* Sends Metrics to Graphite's Carbon daemon using TCP or UDP
* Can collect Windows Performance Counters
* Can collect values by using T-SQL queries against MS SQL databases
* Converts time to UTC on sending
* All configuration can be done from a simple XML file
* Allows you to override the hostname in Windows Performance Counters before sending on to Graphite
* Allows renaming of metric names using regex via the configuration file
* Reloads the XML configuration file automatically. For example, if more counters are added to the configuration file, the script will notice and start sending metrics for them to Graphite in the next send interval
* Additional functions are exposed that allow you to send data to Graphite from PowerShell easily. [Here](#functions) is the list of included functions
* Script can be installed to run as a service
* Installable by Chef Cookbook [which is available here](https://github.com/tas50/chef-graphite_powershell_functions/)
* Installable by Puppet [which is available here](https://forge.puppetlabs.com/opentable/graphite_powershell)
* Supports Hosted Graphite (https://www.hostedgraphite.com)
* Send metrics based on if a windows service is up or down

## Installation

1. Download the repository and place into a PowerShell Modules directory called **Graphite-Powershell**. The module directories can be found by running `$env:PSModulePath` in PowerShell. For example, `C:\Program Files\WindowsPowerShell\Modules\Graphite-PowerShell`
1. Verify your folder structure looks like this, with the *.psd1* and *.psm1* files inside the **Graphite-Powershell** folder:

 ![alt text](http://i.imgur.com/4wE9Xq5.jpg "Start-StatsToGraphite with Verbose Output")
3. Make sure the files are un-blocked by right clicking on them and going to properties.
4. Modify the *StatsToGraphiteConfig.xml* configuration file. Instructions [here](#config).
5. Open PowerShell and ensure you set your Execution Policy to allow scripts be run. For example `Set-ExecutionPolicy RemoteSigned`.

### Modifying the Configuration File

The configuration file is fairly self-explanatory, but here is a description for each of the values.

#### <a name="config"></a>Graphite Configuration Section

Configuration Name | Description
--- | ---
CarbonServer | The server name where Carbon is running. The Carbon daemon is usually running on the Graphite server.
CarbonServerPort | The port number for Carbon. Its default port number is 2003.
MetricPath | The path of the metric you want to be sent to the server. If you are using HostedGraphite, put your API key before the rest of the metric path, for example `YOUR-API-KEY.datacenter1.servers`.
NodeHostName | This allows you to override the hostname of the server before sending the metrics on to Graphite. Default is use `$env:COMPUTERNAME`, which will use the local computer name.
MetricSendIntervalSeconds | The interval to send metrics to Carbon; I recommend 5 seconds or greater. The more metrics you are collecting the longer it takes to send them to the Graphite server. You can see how long it takes to send the metrics each time the loop runs by using running the `Start-StatsToGraphite` function and having *VerboseOutput* set to *True*.
SendUsingUDP | Sends metrics via UDP instead of TCP.

#### Performance Counters Configuration Section

This section lists the performance counters you want the machine to send to Graphite. You can get these from Performance Monitor (perfmon.exe) or by using the command `typeperf -qx` in a command prompt.

I have included some basic performance counters in the configuration file. Asterisks can be used as a wildcard.

Here are some other examples:

* `<Counter Name="\Web Service(YourIISWebSite)\Total Bytes Received"/>`
* `<Counter Name="\Web Service(YourIISWebSite)\Total Bytes Sent"/>`
* `<Counter Name="\ASP.NET Apps v4.0.30319(_lm_w3svc_1_Root_YourIISApp)\Request Wait Time"/>`
* `<Counter Name="\PhysicalDisk(*)\Avg. Disk Write Queue Length"/>`

#### MetricReplace Configuration Section

This section lists regex find and replace rules used to clean up the Windows performance counters before sending them on to Graphite. Most people will be able to leave this section alone as it configured using sensible defaults.

The script processes these in the order they appear in the configuration file. **Order is important!**

There are two methods for replacing metrics with custom names:

1. **Replace with custom value.** This does a regex search on `This`, and replaces it with the value in `With`. For example:
`<MetricReplace This="\#" With="num"/>`
This would find the *#* symbol and replace it with the text *num*
1. **Replace with RegEx capture group.** This does a regex search on `This`, and then replaces it with the value in `With`. It then uses the RegEx capture that was found and substities it for `#{CAPTUREGROUP}`. This this will only work for the first capture. For example:
`<MetricReplace This="physicaldisk\(.* (.*)\:\)" With="physicaldisk.#{CAPTUREGROUP}-drive"/>`
This would capture the drive letter of the phyiscal disk, and replace the whole string with physicaldisk.*DriverLetter*-drive.

If you want to use the regex capture replace, I recommend doing this first, as it's easier to capture these sections before the metrics get cleaned.

#### Filtering Configuration Section

This section lists names you want to filter out of the Performance Counter list. Filtering is useful when you want to use a wildcard in the performance counter, but want to exclude some of the returned counters. I have included *isatap* and *teredo tunneling* by default to filter out IPv6 interfaces. Remove all <MetricFilter> tags if you want no filtering.

#### MSSQLMetics Configuration Section

This section allows you to configure the additional settings that will be used when running the `Start-SQLStatsToGraphite` command.

Configuration Name | Description
--- | ---
MetricPath | The path of the SQL metric you want to be sent to the server
MetricSendIntervalSeconds | The interval to send SQL metrics to Carbon. I recommend 5 seconds or greater. The more queries you are running the longer it takes to send them to the Graphite server. You can see how long it takes to send the metrics each time the loop runs by using running the `Start-SQLStatsToGraphite -Verbose -TestMode`.
SQLConnectionTimeoutSeconds | The time out period when attempting to connect to the SQL Server.
SQLQueryTimeoutSeconds | The time out period when waiting for a SQL query to return.

The next section allows you to configure a list of SQL servers and the queries that will be run against those servers. You can add as many queries or servers as required. The only constraint is that they all need to be able to run within the time given by the **MetricSendIntervalSeconds** configuration value.

`<SQLServer>` Configuration Values | Description
--- | ---
ServerInstance | The hostname or Server Instance of the SQL server you want to connect to. SQL servers with instances can also be used.
Username | The username to connect to SQL with using SQL Authentication. Leaving this and the *Password* option blank will make the script use Windows Authentication against the SQL Server. The current credentials that the PowerShell window are running under will be used.
Password | The password to connect to SQL with using SQL Authentication. Leaving this and the *Username* option blank will make the script use Windows Authentication against the SQL Server. The current credentials that the PowerShell window are running under will be used.

The next part of the configuration allows you to add a list of the T-SQL queries that will be run against the SQL server.

`<Query>` Configuration Values | Description
--- | ---
Database | The database that the SQL query will be run against.
MetricName | The Graphite metric name to use for this SQL query.
TSQL | The T-SQL query to run against the SQL Server. If you need to use characters such as `<` or `>` in your query, you will need to replace them with the appropriate XML entity reference. For example, `>` would be replaced with `&gt;`. A full list of these can be found [on MSDN](http://msdn.microsoft.com/en-us/library/windows/desktop/dd892769%28v=vs.85%29.aspx).

There are a few important things to keep in mind when using this feature.

* If you provide the SQL **Username** and **Password** options, they is stored in plain text in the configuration file. If you do not provide a username and password, the windows account that the PowerShell window is running under will be used against the SQL Server. This is a good way to protect the credentials.
* There is no verification that the SQL command in the configuration file is not destructive. Be sure to use a low privilege account to authenticate against SQL so that any malicious T-SQL queries don't destroy your data.
* If your T-SQL query returns multiple results, only the first one will be sent over to Graphite.

#### Logging Configuration Section

This section allows you to turn on or off Verbose output. This is useful when testing but is better left off when running as a service as you won't be able to see the output.

Configuration Name | Description
--- | ---
VerboseOutput | Will provide each of the metrics that were sent over to Carbon and the total execution time of the loop.

## Usage - Windows Performance Counters

The following shows how to use the `Start-StatsToGraphite`, which will collect Windows performance counters and send them to Graphite.

1. Open PowerShell
2. Import the Module by running `Import-Module -Name Graphite-PowerShell`
3. Start the script by using the function `Start-StatsToGraphite`. If you want Verbose details, use `Start-StatsToGraphite -Verbose`.

You may need to run the PowerShell instance with Administrative rights depending on the performance counters you want to access. This is due to the scripts use of the `Get-Counter` CmdLet.

From the [Get-Counter help page on TechNet](http://technet.microsoft.com/library/963e9e51-4232-4ccf-881d-c2048ff35c2a(v=wps.630).aspx):

> Performance counters are often protected by access control lists (ACLs). To get all available performance counters, open Windows PowerShell with the "Run as administrator" option.

The below image is what `Start-StatsToGraphite` like with **VerboseOutput** turned on in the XML configuration file looks like.

![alt text](http://i.imgur.com/G3pwnhf.jpg "Start-StatsToGraphite with Verbose Output")

That is all there is to getting your Windows performance counters into Graphite.

## Usage - SQL Query Results

The following shows how to use the `Start-SQLStatsToGraphite`, which will execute any SQL queries listed in the configuration file and send the result (which needs to be an integer) to Graphite.

1. Open PowerShell
2. Import the Module by running `Import-Module -Name Graphite-PowerShell`
3. Start the script by using the function `Start-SQLStatsToGraphite`. If you want Verbose detailed use `Start-SQLStatsToGraphite -Verbose`. If you want to see what would be sent to Graphite, without actually sending the metrics, use `Start-SQLStatsToGraphite -Verbose -TestMode`

The below image is what `Start-SQLStatsToGraphite` like with **VerboseOutput** turned on in the XML configuration file looks like.

![alt text](http://i.imgur.com/aFVttVg.jpg "Start-SQLStatsToGraphite with Verbose Output")

This function requires the Microsoft SQL PowerShell Modules/SnapIns. The easiest way to get these is to download them from the [SQL 2012 R2 SP1 Feature Pack](http://www.microsoft.com/en-us/download/details.aspx?id=35580). You will need to grab the following:
* Microsoft® SQL Server® 2012 Shared Management Object
* Microsoft® System CLR Types for Microsoft® SQL Server® 2012
* Microsoft® Windows PowerShell Extensions for Microsoft® SQL Server® 2012

## Installing as a Service

Once you have edited the configuration file and verified everything is functioning correctly by running either `Start-StatsToGraphite` or `Start-SQLStatsToGraphite` in an interactive PowerShell session, you might want to install one or both of these scripts as a service.

The easiest way to achieve this is using NSSM - the Non-Sucking Service Manager.

1. Download nssm from [nssm.cc](http://nssm.cc)
2. Open up an Administrative command prompt and run `nssm install GraphitePowerShell`. (You can call the service whatever you want).
3. A dialog will pop up allowing you to enter in settings for the new service. The following two tables below contains the settings to use.

![alt text](http://i.imgur.com/sDjBcjl.jpg "NSSM Dialog")

4. Click *Install Service*
5. Make sure the service is started and it is set to Automatic
6. Check your Graphite server and make sure the metrics are coming in

The below configurations will show how to run either `Start-StatsToGraphite` or `Start-SQLStatsToGraphite` as a service. If you want to run both on the same server, you will need to create two seperate services, one for each script.

### Running Start-StatsToGraphite as a Service

The following configuration can be used to run `Start-StatsToGraphite` as a service.

Setting Name | Value
--- | ---
Path | C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
Startup Directory | Leave Blank
Options | -command "& { Import-Module -Name Graphite-PowerShell ; Start-StatsToGraphite }"

### Running Start-SQLStatsToGraphite as a Service

The following configuration can be used to run `Start-SQLStatsToGraphite` as a service.

Setting Name | Value
--- | ---
Path | C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
Startup Directory | Leave Blank
Options | -command "& { Import-Module -Name Graphite-PowerShell ; Start-SQLStatsToGraphite }"

If you want to remove a service, read the NSSM documentation [http://nssm.cc/commands](http://nssm.cc/commands) for instructions.

### Installing as a Service Using PowerShell
1. Download nssm from [nssm.cc](http://nssm.cc) and save it into a directory
2. Open an Administrative PowerShell consolen and browse to the directory you saved NSSM
3. Run `Start-Process -FilePath .\nssm.exe -ArgumentList 'install GraphitePowerShell "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "-command "& { Import-Module -Name Graphite-PowerShell ; Start-StatsToGraphite }"" ' -NoNewWindow -Wait`
4. Check the service installed successfully `Get-Service -Name GraphitePowerShell`
5. Start the service `Start-Service -Name GraphitePowerShell`

## <a name="functions">Included Functions</a>

There are several functions that are exposed by the module which are available to use in an ad-hoc manner.

For a list of functions in the module, run `Get-Command -Module Graphite-PowerShell`. For full help for these functions run `Get-Help | <Function Name>`

Function Name | Description
--- | ---
ConvertTo-GraphiteMetric | Takes the Windows Performance counter name and coverts it to something that Graphite can use.
Send-BulkGraphiteMetrics | Sends several Graphite Metrics to a Carbon server with one request. Bulk requests save a lot of resources for Graphite server.
Send-GraphiteEvent | Sends an event to Graphite using the Graphite Event API. More information about the events API can be found [in this blog post](http://obfuscurity.com/2014/01/Graphite-Tip-A-Better-Way-to-Store-Events).
Send-GraphiteMetric | Allows you to send metrics to Graphite in an ad-hoc manner.
Start-SQLStatsToGraphite | The function to query SQL. This is an endless loop which will send metrics to Graphite.
Start-StatsToGraphite | The function to collect Windows Performance Counters. This is an endless loop which will send metrics to Graphite.
