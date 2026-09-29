[CmdletBinding(SupportsShouldProcess = $true)]
param([string]$SubscriptionId)

$subscriptionArguments = if ($SubscriptionId) { @('--subscription', $SubscriptionId) } else { @() }

1..4 | ForEach-Object {
    $name = 'rg-copilot-hack-stale-{0:D2}' -f $_
    if ($PSCmdlet.ShouldProcess($name, 'az group delete')) {
        az group delete --name $name --yes --no-wait @subscriptionArguments --output none
    }
}
