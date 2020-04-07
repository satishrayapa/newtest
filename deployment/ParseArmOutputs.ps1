# Make outputs from resource group deployment available to subsequent tasks

$outputs = ConvertFrom-Json $($env:ArmOutput)
foreach ($output in $outputs.PSObject.Properties) {
  Write-Host "Setting Variable: armOutput_$($output.Name)"
  Write-Host "##vso[task.setvariable variable=armOutput_$($output.Name)]$($output.Value.value)"
}