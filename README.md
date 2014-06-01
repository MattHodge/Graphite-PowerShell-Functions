# Graphite PowerShell Functions

A group of PowerShell functions that allow you to send Windows Performance counters to a Graphite Server, all configurable from a simple XML file.

More details at [http://www.hodgkins.net.au/mswindows/using-powershell-to-send-metrics-graphite/](http://www.hodgkins.net.au/mswindows/using-powershell-to-send-metrics-graphite/)

## Features

* Sends Metrics to Graphite's Carbon daemon using UDP
* Can collect Windows Performance Counters
* Can collect values by using T-SQL queries against MS SQL databases
* Will convert time zones. If your the server you want the metrics sent from is in a different time zone than your Graphite server, the script will convert the time so metrics come in with a time that matches the Graphite serve
* All configuration can be done from a simple XML file
* Reloads the XML file automatically, so if more counters are added, next send interval, the script will pick up and changes or additional counters you added and start sending metrics for them to Graphite
* Additional functions are exposed that allow you to send data to Graphite from PowerShell easily. [Here](#functions) is a list of included functions.
* Can be run as a service
* Installable by Chef. Cookbook [https://github.com/tas50/chef-graphite_powershell_functions](available here)

## Installation

1. Download the *Graphite-PowerShell.ps1* file and the *StatsToGraphiteConfig.xml* configuration file into the same directory, for example *C:\GraphitePowerShell*
2. Make sure the files are un-blocked by right clicking on them and going to properties.
3. Modify *StatsToGraphiteConfig.xml* configuration file. Instructions [here](#config).
4. Open PowerShell and ensure you set your Execution Policy to allow scripts be run, for example `Set-ExecutionPolicy RemoteSigned`.

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

#### MSSQLMetics Configuration Section

This section allows you to configure the additional settings that will be used when running the `Start-SQLStatsToGraphite` command.

Configuration Name | Description
--- | ---
MetricPath | The path of the SQL metric you want to be sent to the server
MetricSendIntervalSeconds | The interval to send SQL metrics to Carbon. I recommend 5 seconds or greater. The more queries you are running the longer it takes to send them to the Graphite server. You can see how long it takes to send the metrics each time the loop runs by using running the `Start-SQLStatsToGraphite -Verbose -TestMode`.
SQLConnectionTimeoutSeconds | The time out period when attempting to connect to the SQL Server.
SQLQueryTimeoutSeconds | The time out period when waiting for a SQL query to return.

Under that you can configure a list of SQL servers and the queries that will be run against those servers. You can add as many queries or servers as required. The only constraint is that they all need to be able to run within the time given by the **MetricSendIntervalSeconds** configuration value.

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
* There is no verification that the SQL command in the configuration file is not destructive. Be sure to use a low privilege account to authenticate against SQL so that any malicious T-SQL queries destroy your data.
* If your T-SQL query returns multiple results, only the first one will be sent over to Graphite.

#### Logging Configuration Section

This section allows you to turn on or off Verbose output. This is useful when testing but is better left off when running as a service.

Configuration Name | Description
--- | ---
VerboseOutput | Will provide each of the metrics that were sent over to Carbon and the total execution time of the loop.

## Usage - Windows Performance Counters

The following shows how to use the `Start-StatsToGraphite`, which will collect Windows performance counters and send them to Graphite.

1. In PowerShell, enter the directory the you downloaded the script, and dot source it `. .\Graphite-PowerShell.ps1`
2. Start the script by using the function `Start-StatsToGraphite`. If you want Verbose detailed use `Start-StatsToGraphite -Verbose`.

You may need to run the PowerShell instance with Administrative rights depending on the performance counters you want to access. This is due to the scripts use of the `Get-Counter` CmdLet. 

From the [Get-Counter help page on TechNet](http://technet.microsoft.com/library/963e9e51-4232-4ccf-881d-c2048ff35c2a(v=wps.630).aspx):

> Performance counters are often protected by access control lists (ACLs). To get all available performance counters, open Windows PowerShell with the "Run as administrator" option.

This is what the verbose output looks like when it is turned on in the XML configuration file.

![alt text](http://i.imgur.com/G3pwnhf.jpg "Verbose")

That is all there is too getting your Windows performance counters into Graphite.

## Usage - SQL Query Results

The following shows how to use the `Start-SQLStatsToGraphite`, which execute any SQL queries listed in the configuration file and send the result (which needs to be an integer) to Graphite.

1. In PowerShell, enter the directory the you downloaded the script, and dot source it `. .\Graphite-PowerShell.ps1`
2. Start the script by using the function `Start-SQLStatsToGraphite`. If you want Verbose detailed use `Start-SQLStatsToGraphite -Verbose`. If you want to see what would be sent to Graphite, without actually sending the metrics, use `Start-SQLStatsToGraphite -Verbose -TestMode`

## Installing as a Service

Once you have edited the configuration file and verified everything is functioning correctly by running either `Start-StatsToGraphite` or `Start-SQLStatsToGraphite` in an interactive PowerShell session, you might want to install one or both of these scripts as a service.

The easiest way to achieve this is using NSSM - the Non-Sucking Service Manager.

1. Download nssm from [nssm.cc](http://nssm.cc)
2. Open up an Administrative command prompt and run `nssm install GraphitePowerShell`. (You can call the service whatever you want).
3. A dialog will pop up allowing you to enter in settings for the new service. The table below contains the settings.

![alt text](http://i.imgur.com/xkiRZgu.jpg "NSSM Dialog")

4. Click *Install Service*
5. Make sure the service is started and it is set to Automatic
6. Check your Graphite server and make sure the metrics are coming in

The below configurations will show how to run either `Start-StatsToGraphite` or `Start-SQLStatsToGraphite` as a service. If you want to run both on the same server, you will need to create two seperate services, one for each script.

### Running Start-StatsToGraphite as a Service

The following configuration can be used to run `Start-StatsToGraphite` as a service. 

Setting Name | Value
--- | ---
Path | C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
Startup Directory | C:\GraphitePowerShell
Options | -command "& { . C:\GraphitePowerShell\Graphite-PowerShell.ps1; Start-StatsToGraphite }"

### Running Start-SQLStatsToGraphite as a Service

The following configuration can be used to run `Start-SQLStatsToGraphite` as a service. 

Setting Name | Value
--- | ---
Path | C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
Startup Directory | C:\GraphitePowerShell
Options | -command "& { . C:\GraphitePowerShell\Graphite-PowerShell.ps1; Start-SQLStatsToGraphite }"

If you want to remove a service, read the NSSM documentation [http://nssm.cc/commands](http://nssm.cc/commands).

### Installing as a Service Using PowerShell
1. Download nssm from [nssm.cc](http://nssm.cc) and save it into your `C:\GraphitePowerShell` directory
2. Open an Administrative PowerShell console
3. Run `Start-Process -FilePath .\nssm.exe -ArgumentList 'install GraphitePowerShell "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "-command "& { . C:\GraphitePowerShell\Graphite-PowerShell.ps1; Start-StatsToGraphite }"" ' -NoNewWindow -Wait`
4. Check the service installed successfully `Get-Service -Name GraphitePowerShell`
5. Start the service `Start-Service -Name GraphitePowerShell`

## <a name="functions">Included Functions

A handful of functions used with the script, which are exposed and available to use in an ad-hoc manner.

For full help for these functions run the PowerShell command `Get-Help | <Function Name>`

Function Name | Description
--- | ---
Start-StatsToGraphite | The function to collect Windows Performance Counters. This is an endless loop which will send metrics to Graphite. 
Start-SQLStatsToGraphite | The function to query SQL. This is an endless loop which will send metrics to Graphite. 
ConvertTo-GraphiteMetric | Takes the Windows Performance counter name and coverts it to something that Graphite can use.
Send-GraphiteMetric | Allows you to send metrics to Graphite in an ad-hoc manner.
Convert-TimeZone | Converts from one time zone to another.
Import-XMLConfig | Loads the XML Configuration file. Not really useful out side of the script.
