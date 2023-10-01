param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $TenantId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ClientId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ClientSecret,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ServiceIdentifier
)


#################################################################################################################
Write-Host "Getting access token"

try {
    $res = Invoke-RestMethod -Method POST `
        -Uri "https://login.microsoftonline.com/$TenantId/oauth2/token" `
        -Body @{ resource = $ServiceIdentifier; grant_type = "client_credentials"; client_id = $ClientId; client_secret = $ClientSecret }`
        -ContentType "application/x-www-form-urlencoded"
    $access_token = $res.access_token
    #$access_token
    if ($access_token) {
        Write-Host "Access token fetched successfully"
    }
}
catch {
    Write-Host "An exception occurred while fetching access token $($_.Exception.Message)"
}

#################################################################################################################
#################################################################################################################

Write-Host "Getting Environment Configurations"
try {
    $Uri = "$($env:HostURL)/api/Tenant/configuration"

    $reqHeaders = @{
        "Authorization" = "Bearer $($access_token)";
        "Accept"        = "application/json";
    }

    $apiResponse = Invoke-RestMethod -Method GET -Uri $Uri -Headers $reqHeaders

    if ($apiResponse) {
        $environmentConfig = $apiResponse | ConvertTo-Json -Compress
    }


    Write-Output "EnvironmentConfig=$environmentConfig" >> $env:GITHUB_OUTPUT

    $env:GITHUB_OUTPUT
}
catch {
    Write-Host "An exception occurred while fetching environment configurations $($_.Exception.Message)"
}
