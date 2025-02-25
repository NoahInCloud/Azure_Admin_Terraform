param (
    [string]$devName = "cl01"
)

# Ensure Microsoft Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Force -AllowClobber
}

# Connect to Microsoft Graph with required scopes
Connect-MgGraph -Scopes "Device.Read.All","DeviceLocalCredential.Read.All" -Force

# Get the device details by searching for its display name.
$devDetails = Get-MgDevice -Search "displayName:$devName" -ConsistencyLevel eventual
if (-not $devDetails) {
    Write-Error "Device not found."
    exit 1
}

# Construct the URI for device local credentials (beta endpoint)
$uri = "https://graph.microsoft.com/beta/deviceLocalCredentials/$($devDetails.DeviceId)?`$select=credentials"

# Invoke the Microsoft Graph request
$response = Invoke-MgGraphRequest -Method Get -Uri $uri

if ($response -and $response.credentials -and $response.credentials.Count -gt 0) {
    $passwordBase64 = $response.credentials[0].passwordBase64
    $passwordPlain = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($passwordBase64))
    $result = @{
        deviceId = $devDetails.DeviceId
        password = $passwordPlain
    }
    # Output the result as JSON
    $result | ConvertTo-Json -Depth 10
} else {
    Write-Error "No credentials found."
    exit 1
}

Disconnect-MgGraph
