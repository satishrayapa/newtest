param(
    [Parameter(Mandatory = $true)]   [String]$StorageAccountName,
    [Parameter(Mandatory = $true)]   [String]$Location,
    [Parameter(Mandatory = $true)]   [String]$BuildId,
    [Parameter(Mandatory = $true)]   [String]$VMName,
    [Parameter(Mandatory = $true)]   [String]$SubscriptionId,
    [Parameter(Mandatory = $true)]   [String]$ResourceGroupName,
    [Parameter(Mandatory = $true)]   [String]$AdminPassword,
    [Parameter(Mandatory = $false)]  [String]$StartScript  
)

if (!$StartScript) {
    $StartScript = "ConfigureServer.ps1"
}

$StorageKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName -ErrorAction Stop).Value[0]

$sacct = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

Write-Host "Building list of files to download" -ForegroundColor cyan

$staticUrl = "$($sacct.PrimaryEndpoints.Blob)build"
$staticFiles = @("setup.ini","SSMS-Setup-ENU.exe","SQLServer2017-SSEI-Dev.exe", "Aumentum_Release.2019.20.02.8083.512758.zip", "AumentumDB.2019.20.02.8083.512758.zip", "AumentumServices.2019.20.02.8083.512758.zip")

$dynamicUrl = "$($sacct.PrimaryEndpoints.Blob)build/$BuildId"
$dynamicFiles = @($StartScript)

$fileUris = @()
foreach ($file in $staticFiles) {
    $fileUris += "$staticUrl/$file"
}

foreach ($file in $dynamicFiles) {
    $fileUris += "$dynamicUrl/$file"
}

$settings = @{"fileUris" = $fileUris };
$fileUris

$runId = (New-Guid).ToString()

$PSCommand = "powershell -ExecutionPolicy Unrestricted -File $BuildId\$StartScript -RunId $runId -AdminPassword $AdminPassword -Verbose"

$protectedSettings = @{ 
    "storageAccountName" = $StorageAccountName; 
    "storageAccountKey"  = $StorageKey; 
    "commandToExecute"   = $PSCommand;
};

#run command

Write-Host "Run Azure VM extension" -ForegroundColor cyan

try {

    Set-AzVMExtension -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -VMName $VMName `
        -Name "Install" `
        -Publisher "Microsoft.Compute" `
        -ExtensionType "CustomScriptExtension" `
        -TypeHandlerVersion "1.9" `
        -Settings $settings  `
        -ProtectedSettings $protectedSettings `
        -ErrorAction Stop

}
catch {
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status
	
    $o = ($vm.Extensions | Where-Object { $_.Type -eq "Microsoft.Compute.CustomScriptExtension" }).Substatuses | Where { $_.DisplayStatus -ne "Provisioning succeeded" }

    if ($o.Count -eq 0) {
        Write-Host (($vm.Extensions | Where-Object { $_.Type -eq "Microsoft.Compute.CustomScriptExtension" }).Substatuses | Out-String)
        return
    }

    Write-Error ( ($vm.Extensions | Where-Object { $_.Type -eq "Microsoft.Compute.CustomScriptExtension" }).Substatuses | Out-String)
    throw
}

