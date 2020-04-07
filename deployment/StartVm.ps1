param(    
    [Parameter(Mandatory=$true)]   [String]$VMName,
    [Parameter(Mandatory=$true)]   [String]$ResourceGroupName)
$vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status

if ($vm.Statuses[$vm.Statuses.Count - 1].Code -eq "PowerState/deallocated") {
    Start-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
}
