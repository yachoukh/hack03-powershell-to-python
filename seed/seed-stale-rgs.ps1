[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Location = 'swedencentral',
    [string]$SubscriptionId
)

$subscriptionArguments = if ($SubscriptionId) { @('--subscription', $SubscriptionId) } else { @() }

$resourceGroups = @(
    @{ Name = 'rg-copilot-hack-stale-01'; Tags = @{ purpose = 'copilot-hackathon'; owner = 'platform'; costCenter = 'CC-1001'; environment = 'dev'; application = 'hack03'; dataClassification = 'internal'; expiresOn = '2025-01-01'; lastReviewed = '2025-01-01' } },
    @{ Name = 'rg-copilot-hack-stale-02'; Tags = @{ purpose = 'copilot-hackathon'; owner = 'platform'; costCenter = 'CC-1001'; environment = 'dev'; application = 'hack03'; dataClassification = 'internal'; expiresOn = '2099-12-31'; lastReviewed = (Get-Date -Format 'yyyy-MM-dd') } },
    @{ Name = 'rg-copilot-hack-stale-03'; Tags = @{ purpose = 'copilot-hackathon'; owner = 'platform'; costCenter = 'CC-1001'; environment = 'dev'; application = 'hack03'; dataClassification = 'internal'; expiresOn = '2099-12-31'; lastReviewed = '2025-06-01' } },
    @{ Name = 'rg-copilot-hack-stale-04'; Tags = @{ purpose = 'copilot-hackathon'; costCenter = 'CC-1001'; environment = 'dev'; application = 'hack03'; dataClassification = 'internal'; expiresOn = '2099-12-31'; lastReviewed = (Get-Date -Format 'yyyy-MM-dd') } }
)

foreach ($resourceGroup in $resourceGroups) {
    $tagArguments = $resourceGroup.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
    if ($PSCmdlet.ShouldProcess($resourceGroup.Name, 'az group create')) {
        az group create --name $resourceGroup.Name --location $Location --tags $tagArguments @subscriptionArguments --output none
    }
}
