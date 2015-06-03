Import-Module .\Graphite-Powershell.psd1 -Force

InModuleScope Graphite-PowerShell {
    Describe "Import-XMLConfig" {
        Context "Loading a Configuration File" {
            $_config = Import-XMLConfig -ConfigPath "$(Get-Location)\StatsToGraphiteConfig.xml"

            It "Loaded Configuration File Should Not Be Empty" {
                $_config | Should Not BeNullOrEmpty
            }
            It "Should Have 16 Properties" {
                $_config.Count | Should Be 17
            }
            It "SendUsingUDP should be Boolean" {
                $_config.SendUsingUDP -is [Boolean] | Should Be $true
            }
            It "MSSQLMetricSendIntervalSeconds should be Int32" {
                $_config.MSSQLMetricSendIntervalSeconds -is [Int32] | Should Be $true
            }
            It "MSSQLConnectTimeout should be Int32" {
                $_config.MSSQLConnectTimeout -is [Int32] | Should Be $true
            }
            It "MSSQLQueryTimeout should be Int32" {
                $_config.MSSQLQueryTimeout -is [Int32] | Should Be $true
            }
            It "MetricSendIntervalSeconds should be Int32" {
                $_config.MetricSendIntervalSeconds -is [Int32] | Should Be $true
            }
            It "MetricTimeSpan should be TimeSpan" {
                $_config.MetricTimeSpan -is [TimeSpan] | Should Be $true
            }
            It "MSSQLMetricTimeSpan should be TimeSpan" {
                $_config.MSSQLMetricTimeSpan -is [TimeSpan] | Should Be $true
            }
            It "MetricReplace should be HashTable" {
                $_config.MetricReplace -is [System.Collections.Specialized.OrderedDictionary] | Should Be $true
            }
        }
    }
    
    Describe "Format-PerformanceCounter" {
        Context "Single Counter" {
            $_out = Get-Counter -Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 | Format-PerformanceCounter
            It "Has a TimeStamp" {
                $_out.TimeStamp | Should Not BeNullOrEmpty
            }
            It "TimeStamp is of type [System.DateTime]" {
                $_out.TimeStamp -is [System.DateTime] | Should Be $true
            }
            It "Has a Name" {
                $_out.Name | Should Not BeNullOrEmpty
            }
            It "Has a Name of '\\$($env:COMPUTERNAME)\processor(_total)\% processor time'" {
                $_pathOutput = "\\$($env:COMPUTERNAME)\processor(_total)\% processor time"
                $_out.Name | Should Match ([regex]::Escape($_pathOutput))
            }
            It "Has a Value" {
                $_out.Value | Should Not BeNullOrEmpty
            }
            It "Value is of type [System.Double]" {
                $_out.Value -is [System.Double] | Should Be $true
            }
            It "Value is between 0 and 100" {
                $_out.Value -ge 0 -and $_out.Value -le 100 | Should Be $true
            }
        }
        Context "Multiple Counters" {
            $_counterArray = @('\Processor(_Total)\% Processor Time', '\Memory\Available MBytes')

            $_out = Get-Counter -Counter $_counterArray -SampleInterval 1 -MaxSamples 1 | Format-PerformanceCounter
            It "TimeStamp Array of length 2" {
                $_out.TimeStamp.Length | Should Be 2
            }
            It "Has a TimeStamp" {
                $_out.TimeStamp | Should Not BeNullOrEmpty
            }
            It "TimeStamp is an array [System.Array]" {
                $_out.TimeStamp -is [System.Array] | Should Be $true
            }
            It "Has a Name" {
                $_out.Name | Should Not BeNullOrEmpty
            }
            It "Name is an array [System.Array]" {
                $_out.Name -is [System.Array] | Should Be $true
            }
            It "Has a Value" {
                $_out.Value | Should Not BeNullOrEmpty
            }
            It "Value is an array [System.Array]" {
                $_out.Value -is [System.Array] | Should Be $true
            }
        }
    }

    Describe "ConvertTo-UTCUnixTime" {

        $DateTime = Get-Date -Date "2015-04-20T11:11:11+00:00"
        $_returnedTime = $DateTime | ConvertTo-UTCUnixTime
        It "Returns something" {
            $_returnedTime | Should Not BeNullOrEmpty
        }
        It "Return object is of type [System.UInt64]" {
            $_returnedTime -is [System.UInt64] | Should Be $true
        }
        It "Returns a Unix Time of 1429528271" {
            $_returnedTime | Should BeExactly "1429528271"
        }
    }

    Describe "ConvertTo-GraphiteMetricName" {
        Context "Metric Transformation - Using MetricReplacementHash" {

            $MockHashTable = [ordered]@{
            "^\\\\" = "";
            "\\\\" = "";
            "\/" = "-";
            ":" = ".";
            "\\" = ".";
            "\(" = ".";
            "\)" = "";
            "\]" = "";
            "\[" = "";
            "\%" = "";
            "\s+" = "";
            "\.\." = ".";
            "_" = ""
            }

            It "Should Return Something" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not BeNullOrEmpty
            }
            It "Should Provide myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec as Output" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should MatchExactly "myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec"
            }
            It "Should Not Contain Left Parentheses" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\("
            }
            It "Should Not Contain Right Parentheses" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\)"
            }
            It "Should Not Contain Forward Slash" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\/"
            }
            It "Should Not Contain Back Slash" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\\"
            }
            It "Should Contain a Period" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Match "\."
            }
            It "Should Not Have HostName Renamed To CustomHostName" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\$env:COMPUTERNAME\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should MatchExactly "$env:COMPUTERNAME.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec"
            }
        }
        Context "Metric Transformation - Replacing HostName" {
            $MockHashTable = [ordered]@{
            "$env:COMPUTERNAME" = "CustomHostName";
            "^\\\\" = "";
            "\\\\" = "";
            "\/" = "-";
            ":" = ".";
            "\\" = ".";
            "\(" = ".";
            "\)" = "";
            "\]" = "";
            "\[" = "";
            "\%" = "";
            "\s+" = "";
            "\.\." = ".";
            "_" = ""
            }

            It "Should Return Something" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not BeNullOrEmpty
            }
            It "Should Provide myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec as Output" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should MatchExactly "myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec"
            }
            It "Should Not Contain Left Parentheses" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\("
            }
            It "Should Not Contain Right Parentheses" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\)"
            }
            It "Should Not Contain Forward Slash" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\/"
            }
            It "Should Not Contain Back Slash" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\\"
            }
            It "Should Contain a Period" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Match "\."
            }
            It "Should Have HostName Renamed To CustomHostName" {
                ConvertTo-GraphiteMetricName -MetricToClean "\\$env:COMPUTERNAME\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should MatchExactly "CustomHostName.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec"
            }
        } 
    }

    Describe "ConvertTo-GraphiteMetric" {

        $MockHashTable = [ordered]@{
        "$env:COMPUTERNAME" = "testhostname";
        "^\\\\" = "";
        "\\\\" = "";
        "\/" = "-";
        ":" = ".";
        "\\" = ".";
        "\(" = ".";
        "\)" = "";
        "\]" = "";
        "\[" = "";
        "\%" = "";
        "\s+" = "";
        "\.\." = ".";
        "_" = ""
        }

        Context "Conversion of Single Formated Performance Counter" {
            $objArray = @()

            $Object1 = New-Object PSObject -Property @{            
                    TimeStamp = ($DateTime = Get-Date -Date "2015-04-20T11:11:11+00:00")              
                    Name = '\\testhostname\memory\available mbytes'              
                    Value = '4000'                     
            }

            $objArray += $Object1

            # Get a result
            $_result = $objArray | ConvertTo-GraphiteMetric -MetricReplacementHash $MockHashTable

            # Split it into an array
            $split = $_result.Split(' ')

            It "return is not null" {
                $_result | Should Not BeNullOrEmpty
            }
            It "return is of type [System.String]" {
                $_result -is [System.String] | Should Be $true
            }
            It "return should have 3 seperate parts seperated by spaces (metricname value unixtime)" {
                $split = $_result.Split(' ')
                $split.Length | Should Be 3
            }
            It "metricname should be 'testhostname.memory.availablembytes'" {
                $split[0] | Should BeExactly 'testhostname.memory.availablembytes'
            }
            It "value should be '4000'" {
                $split[1] | Should BeExactly '4000'
            }
            It "unixtime should be '4000'" {
                $split[2] | Should BeExactly '1429528271'
            }
        }

        Context "Conversion of Single Formated Performance Counter with MetricPrefix" {
            $objArray = @()

            $Object1 = New-Object PSObject -Property @{            
                    TimeStamp = ($DateTime = Get-Date -Date "2015-04-20T11:11:11+00:00")              
                    Name = '\\testhostname\memory\available mbytes'              
                    Value = '4000'                     
            }

            $objArray += $Object1

            # Get a result
            $_result = $objArray | ConvertTo-GraphiteMetric -MetricReplacementHash $MockHashTable -MetricPrefix 'datacenter1.testing'

            # Split it into an array
            $split = $_result.Split(' ')

            It "return is not null" {
                $_result | Should Not BeNullOrEmpty
            }
            It "return is of type [System.String]" {
                $_result -is [System.String] | Should Be $true
            }
            It "return should have 3 seperate parts seperated by spaces (metricname value unixtime)" {
                $split = $_result.Split(' ')
                $split.Length | Should Be 3
            }
            It "metricname should be 'datacenter1.testing.testhostname.memory.availablembytes'" {
                $split[0] | Should BeExactly 'datacenter1.testing.testhostname.memory.availablembytes'
            }
            It "value should be '4000'" {
                $split[1] | Should BeExactly '4000'
            }
            It "unixtime should be '1429528271'" {
                $split[2] | Should BeExactly '1429528271'
            }
        }

        Context "Conversion of Multiple Performance Counters with MetricPrefix" {
            $objArray = @()

            $Object1 = New-Object PSObject -Property @{            
                    TimeStamp = ($DateTime = Get-Date -Date "2015-04-20T11:11:11+00:00")              
                    Name = '\\testhostname\memory\available mbytes'              
                    Value = '4000'                     
            }

            $objArray += $Object1

            $Object2 = New-Object PSObject -Property @{            
                    TimeStamp = ($DateTime = Get-Date -Date "2015-04-20T11:11:12+00:00")              
                    Name = '\\testhostname\processor(_total)\% processor time'             
                    Value = '50.35453546'                     
            }

            $objArray += $Object2

            # Get a result
            $_result = $objArray | ConvertTo-GraphiteMetric -MetricReplacementHash $MockHashTable -MetricPrefix 'datacenter1.testing'


            # Split the second item in the array into its own array
            $split = $_result[1].Split(' ')

            It "return is not null" {
                $_result | Should Not BeNullOrEmpty
            }
            It "return should have a length of 2 items in an array" {
                $_result.Length | Should Be 2
            }
            It "last item in return array should have 3 seperate parts seperated by spaces (metricname value unixtime)" {
                $split = $_result[1].Split(' ')
                $split.Length | Should Be 3
            }
            It "last item in return array metricname should be 'datacenter1.testing.testhostname.processor.total.processortime'" {
                $split[0] | Should BeExactly 'datacenter1.testing.testhostname.processor.total.processortime'
            }
            It "last item in return array value should be '50.35453546'" {
                $split[1] | Should BeExactly '50.35453546'
            }
            It "last item in return array unixtime should be '1429528272'" {
                $split[2] | Should BeExactly '1429528272'
            }
        }
    }
}