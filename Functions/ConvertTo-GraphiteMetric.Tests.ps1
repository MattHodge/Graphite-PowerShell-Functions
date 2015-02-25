$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$toplevel = Split-Path -Parent $here
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here\$sut"

Describe "ConvertTo-GraphiteMetric" {
    Context "Metric Transformation - Base Function" {
        $TestMetric = ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec"

        It "Should Return Something" {
            $TestMetric | Should Not BeNullOrEmpty
        }
        It "Should Provide myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec as Output" {
            $TestMetric | Should MatchExactly "myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec"
        }
        It "Should Not Contain Left Parentheses" {
            $TestMetric | Should Not Match "\("
        }
        It "Should Not Contain Right Parentheses" {
            $TestMetric | Should Not Match "\)"
        }
        It "Should Not Contain Forward Slash" {
            $TestMetric | Should Not Match "\/"
        }
        It "Should Not Contain Back Slash" {
            $TestMetric | Should Not Match "\\"
        }
        It "Should Contain a Period" {
            $TestMetric | Should Match "\."
        }
    }
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
            ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not BeNullOrEmpty
        }
        It "Should Provide myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec as Output" {
            ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should MatchExactly "myServer.networkinterface.realtekpciegbefamilycontroller.bytesreceived-sec"
        }
        It "Should Not Contain Left Parentheses" {
            ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\("
        }
        It "Should Not Contain Right Parentheses" {
            ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\)"
        }
        It "Should Not Contain Forward Slash" {
            ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\/"
        }
        It "Should Not Contain Back Slash" {
            ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Not Match "\\"
        }
        It "Should Contain a Period" {
            ConvertTo-GraphiteMetric -MetricToClean "\\myServer\network interface(realtek pcie gbe family controller)\bytes received/sec" -MetricReplacementHash $MockHashTable | Should Match "\."
        }
    }
    Context "Metric Transformation - Remove Underscores" {
        $TestMetric = ConvertTo-GraphiteMetric -MetricToClean "\\myServer\Processor(_Total)\% Processor Time" -RemoveUnderscores

        It "Should Return Something" {
            $TestMetric | Should Not BeNullOrEmpty
        }
        It "Should Return myServer.production.net.Processor.Total.ProcessorTime as Output" {
            $TestMetric | Should MatchExactly "myServer.Processor.Total.ProcessorTime"
        }
        It "Should Not Contain Underscores" {
            $TestMetric | Should Not Match "_"
        }
    }
    Context "Metric Transformation - Provide Nice Output for Physical Disks" {
        $TestMetric = ConvertTo-GraphiteMetric -MetricToClean "\\myServer\physicaldisk(1 e:)\avg. disk write queue length" -RemoveUnderscores -NicePhysicalDisks

        It "Should Return Something" {
            $TestMetric | Should Not BeNullOrEmpty
        }
        It "Should Return myServer.physicaldisk.e-drive.diskwritequeuelength as Output" {
            $TestMetric | Should MatchExactly "myServer.physicaldisk.e-drive.diskwritequeuelength"
        }
    }
    Context "Metric Transformation - Replace HostName" {
        $TestMetric = ConvertTo-GraphiteMetric -MetricToClean "\\$($env:COMPUTERNAME)\physicaldisk(1 e:)\avg. disk write queue length" -RemoveUnderscores -NicePhysicalDisks -HostName "my.new.hostname"

        It "Should Return Something" {
            $TestMetric | Should Not BeNullOrEmpty
        }
        It "Should Return my.new.hostname.physicaldisk.e-drive.diskwritequeuelength as Output" {
            $TestMetric | Should MatchExactly "my.new.hostname.physicaldisk.e-drive.diskwritequeuelength"
        }

        $TestMetric = ConvertTo-GraphiteMetric -MetricToClean "\\$($env:COMPUTERNAME)\physicaldisk(1 e:)\avg. disk write queue length" -RemoveUnderscores -NicePhysicalDisks -HostName "host_with_underscores"

        It "Should Return host_with_underscores.physicaldisk.e-drive.diskwritequeuelength as Output when RemoveUnderscores is enabled and host has underscores" {
            $TestMetric | Should MatchExactly "host_with_underscores.physicaldisk.e-drive.diskwritequeuelength"
        }
    }
}