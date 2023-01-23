<#
.EXAMPLE
.\cpu_stress.ps1

This will execute the script against all cores

.DESCRIPTION
#>

# CPUs in the machine
$cpus=$env:NUMBER_OF_PROCESSORS
# Lower the thread so it won't overwhelm the system for other things
[System.Threading.Thread]::CurrentThread.Priority = 'Lowest'

#####################
# perfmon counters for CPU
$Global:psPerfCPU = new-object System.Diagnostics.PerformanceCounter("Processor","% Processor Time","_Total")
$psPerfCPU.NextValue() | Out-Null


$StartDate = Get-Date
Write-Output "=-=-=-=-=-=-=-=-=-=  Stress Machine Started: $StartDate =-=-=-=-=-=-=-=-=-="
Write-Warning "This script will saturate all available CPUs in the machine"
Write-Warning "To cancel execution of all jobs, close the PowerShell Host Window (or terminate the remote session)"
Write-Output "=-=-=-=-=-=-=-=-=-=  CPUs in box: $cpus =-=-=-=-=-=-=-=-=-= "



# This will stress the CPU
foreach ($loopnumber in 1..$cpus){
  Start-Job -ScriptBlock{
  $result = 1
      foreach ($number in 1..0x7FFFFFFF){
          $result = $result * $number
      }# end foreach
  }# end Start-Job
}# end foreach

Write-Output "Created sub-jobs to consume the CPU"
# Ask the user if they want to clear out RAM, if so we will continue
Read-Host -Prompt "Press any key to stop the JOBs CTRL+C to quit"

Write-Output "Clearing CPU Jobs"
Receive-Job *
Stop-Job *
Remove-Job *

$EndDate = Get-Date
Write-Output "=-=-=-=-=-=-=-=-=-= Stress Machine Complete: $EndDate =-=-=-=-=-=-=-=-=-="