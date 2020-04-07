$branchName = [Environment]::GetEnvironmentVariable("Build_SourceBranch")

Write-Host "Branch name: $branchName"

$splits = $branchName.Split('/')
if ($splits.Length -ge 4) {
    $stackName = $splits[3]
}
else {
    $stackName = [Environment]::GetEnvironmentVariable("Build_SourceBranchName")
}

Write-Host "##vso[task.setvariable variable=PipelineStackName;]$stackName"
#te