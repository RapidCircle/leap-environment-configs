
#################################################################################################################
Write-Host "Getting access token"

try {
    $requestURL = "https://login.microsoftonline.com/$($env:TenantId)/oauth2/token"

    $reqBody = @{
        resource      = $env:ServiceIdentifier; 
        grant_type    = "client_credentials"; 
        client_id     = $env:ClientId; 
        client_secret = $env:ClientSecret
    }

    $res = Invoke-RestMethod -Method POST -Uri $requestURL -Body $reqBody -ContentType "application/x-www-form-urlencoded"

    if (![string]::IsNullOrEmpty($res)) {
        $access_token = $res.access_token
        if ($access_token) {
            Write-Host "Access token fetched successfully"
        }    
    }
    else {
        Write-Error "Unable to fetch the access token"
        throw "Unable to fetch the access token"
    }
    
}
catch {
    Write-Error "An exception occurred while fetching access token: $($_.Exception.Message)"
    throw "An exception occurred while fetching access token: $($_.Exception.Message)"
}

#################################################################################################################
#################################################################################################################

Write-Host "Getting Environment Configurations"
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
            Write-Output "::add-mask::$ConfigVariableValue" 
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
