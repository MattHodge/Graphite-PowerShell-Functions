$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$toplevel = Split-Path -Parent $here
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here\$sut"

Describe "Importing of XML Configuration File" {
    Context "Loading a Configuration File" {
        $Config = Import-XMLConfig -ConfigPath "$toplevel/StatsToGraphiteConfig.xml"

        It "Loaded Configuration File Should Not Be Empty" {
            $Config | Should Not BeNullOrEmpty
        }
        It "Should Have 16 Properties" {
            $Config.Count | Should Be 16
        }
        It "SendUsingUDP should be Boolean" {
            $Config.SendUsingUDP -is [Boolean] | Should Be $true
        }
        It "MSSQLMetricSendIntervalSeconds should be Int32" {
            $Config.MSSQLMetricSendIntervalSeconds -is [Int32] | Should Be $true
        }
        It "MSSQLConnectTimeout should be Int32" {
            $Config.MSSQLConnectTimeout -is [Int32] | Should Be $true
        }
        It "MSSQLQueryTimeout should be Int32" {
            $Config.MSSQLQueryTimeout -is [Int32] | Should Be $true
        }
        It "MetricSendIntervalSeconds should be Int32" {
            $Config.MetricSendIntervalSeconds -is [Int32] | Should Be $true
        }
        It "MetricTimeSpan should be TimeSpan" {
            $Config.MetricTimeSpan -is [TimeSpan] | Should Be $true
        }
        It "MSSQLMetricTimeSpan should be TimeSpan" {
            $Config.MSSQLMetricTimeSpan -is [TimeSpan] | Should Be $true
        }
    }
}