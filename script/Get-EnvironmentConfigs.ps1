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
Write-Debug "Getting access token"

try {
    $res = Invoke-RestMethod -Method POST `
        -Uri "https://login.microsoftonline.com/$TenantId/oauth2/token" `
        -Body @{ resource = $ServiceIdentifier; grant_type = "client_credentials"; client_id = $ClientId; client_secret = $ClientSecret }`
        -ContentType "application/x-www-form-urlencoded"

    if (![string]::IsNullOrEmpty($res)) {
        $access_token = $res.access_token
        if ($access_token) {
            Write-Debug "Access token fetched successfully"
        }    
    }
    else {
        Write-Error "Unable to fetch the access token"
        throw "Unable to fetch the access token"
    }
    
}
catch {
    Write-Error "An exception occurred while fetching access token $($_.Exception.Message)"
    throw "An exception occurred while fetching access token $($_.Exception.Message)"
}

#################################################################################################################
#################################################################################################################

Write-Debug "Getting Environment Configurations"
try {
    if ([string]::IsNullOrEmpty($env:HostURL)) {
        throw "Host URL cannot be empty"
    }
    
    $Uri = "$($env:HostURL)/api/Tenant/configuration"

    $reqHeaders = @{
        "Authorization" = "Bearer $($access_token)";
        "Accept"        = "application/json";
    }

    $apiResponse = Invoke-RestMethod -Method GET -Uri $Uri -Headers $reqHeaders

    if ($apiResponse) {
        Write-Host "Environment Configurations Fetched Successfully"

        $apiResponse.PSObject.Properties | ForEach-Object {
            $ConfigVariableName = "LEAP_$($_.Name)"
            $ConfigVariableValue = $_.Value

            Write-Output "$ConfigVariableName=$ConfigVariableValue" >> $env:GITHUB_ENV
        }
        
        $environmentConfig = $apiResponse | ConvertTo-Json -Compress

        Write-Output "EnvironmentConfig=$environmentConfig" >> $env:GITHUB_OUTPUT

        $env:GITHUB_OUTPUT
        $env:GITHUB_ENV
    }
}
catch {
    Write-Host "An exception occurred while fetching environment configurations $($_.Exception.Message)"
    throw "An exception occurred while fetching environment configurations $($_.Exception.Message)"
}
