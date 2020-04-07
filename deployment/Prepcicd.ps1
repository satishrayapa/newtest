param($PipelineStackName, [String[]] $VariableArray)

function Set-VariableGroupName($groupName, $groupVariableName) {
    Write-Host "Looking up Variable Group name: $groupName"

    $value = [Environment]::GetEnvironmentVariable($groupName + "_" + $groupVariableName)
	
    if (!$value -or ($value -eq "")) {
        Write-Host "Unable to locate $groupVariableName. Using Global value instead."
        $value = [Environment]::GetEnvironmentVariable("Global_$groupVariableName")
        Write-Host "Using global value $value"
    }
    else {
        Write-Host "Using override value: $value"
    }

	if (!$value -or ($value -eq "")) {
		$value = $groupName
		Write-Host "Using Pipeline Stack Name for $groupVariableName"
		$value = $value.ToLower().Replace("-", "")
	}

	Write-Host "##vso[task.setvariable variable=$groupVariableName;isOutput=true]$value"
}

foreach($variableItem in $VariableArray){
	Write-Host "Processing $variableItem"
	Set-VariableGroupName $PipelineStackName $variableItem
}
