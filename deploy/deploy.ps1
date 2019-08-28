Param (
    [string] $ResourceGroupName = "pwsh-local-rg",
    [string] $Location = "West Europe",
    [string] $Template = "$PSScriptRoot\azuredeploy.json",
    [string] $TemplateParameters = "$PSScriptRoot\azuredeploy.parameters.json",
    [string] $DynamicParameter1 = "parameter2local"
)

$ErrorActionPreference = "Stop"

$date = (Get-Date).ToString("yyyy-MM-dd-HH-mm-ss")
$deploymentName = "Local-$date"

if ([string]::IsNullOrEmpty($env:GITHUB_ACTION))
{
    Write-Host (@"
Not executing inside GitHub action.
Make sure you have done "Login-AzAccount" and
"Select-AzSubscription -SubscriptionName name"
so that script continues to work correctly for you.
"@)
}
else
{
	$deploymentName = $env:GITHUB_SHA
}

if ($null -eq (Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue))
{
    Write-Warning "Resource group '$ResourceGroupName' doesn't exist and it will be created."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose
}

# Create additional parameters that we pass to the template deployment
$additionalParameters = New-Object -TypeName hashtable
$additionalParameters['dynamicParameter1'] = $DynamicParameter1

$result = New-AzResourceGroupDeployment `
	-DeploymentName $deploymentName `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $Template `
    -TemplateParameterFile $TemplateParameters `
    @additionalParameters `
    -Mode Complete -Force `
	-Verbose

$result

if ($null -eq $result.Outputs.variableName)
{
    Throw "Template deployment didn't return 'output' variables correctly and therefore deployment is cancelled."
}

$variableName = $result.Outputs.variableName.value
