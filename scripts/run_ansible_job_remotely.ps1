# Define parameters
param (
    [string]$testVar,  # No default value here
)

# Prompt for testVar if not provided
if (-not $testVar) {
    $testVar = Read-Host "Enter the test variable"
}

# Prompt for targetPaths if not provided
if (-not $targetPaths) {
    Write-Host "Enter the target file names (comma-separated):"
    $targetPathsInput = Read-Host
    $targetPaths = $targetPathsInput -split ",\s*"  # Split input into an array
}

# Enforce TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Bypass SSL certificate validation (for testing only)
# [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define variables
$baseUrl = "https://aap.corp.riotinto.org/api/controller/v2"
$jobTemplateId = "2906"  # Replace with your job template ID

# Prompt for username and password
$username = Read-Host "Enter your Ansible Automation Platform username"
$password = Read-Host "Enter your Ansible Automation Platform password" -AsSecureString
$passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# Encode credentials for Basic Authentication
$authHeader = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:$passwordPlain"))

# Define headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "Basic $authHeader")

# Define extra_vars to pass to the job template
$extraVars = @{
    test_var = $testVar
}

# Convert extra_vars to JSON
$body = @{
    extra_vars = $extraVars
} | ConvertTo-Json -Depth 2 -Compress

# Define the API endpoint for launching the job template
$launchUrl = "$baseUrl/job_templates/$jobTemplateId/launch/"

# Make the API call to launch the job template
$response = Invoke-RestMethod -Uri $launchUrl -Method 'POST' -Headers $headers -Body $body

# Output the response
# $response | ConvertTo-Json -Depth 2

# Extract and display the job ID
$jobId = $response.id
Write-Host "Ansible job launched successfully. Job ID: $jobId"

# Pause before checking the job status
Write-Host "Checking the job status every 30 seconds..."

# Define the API endpoint for checking the job status
$jobStatusUrl = "$baseUrl/jobs/$jobId/"

# Initialize the job status
$jobStatus = ""

# Loop to check the job status until it is finished
do {
    # Make the API call to check the job status
    $jobStatusResponse = Invoke-RestMethod -Uri $jobStatusUrl -Method 'GET' -Headers $headers
    $jobStatus = $jobStatusResponse.status

    # Output the job status
    Write-Host "Job Status: $jobStatus"

    # Wait for 30 seconds before checking again
    if ($jobStatus -notin @("successful", "failed", "canceled")) {
        Start-Sleep -Seconds 30
    }
} while ($jobStatus -notin @("successful", "failed", "canceled"))

# Final status message
if ($jobStatus -eq "successful") {
    Write-Host "Job completed successfully."
} elseif ($jobStatus -eq "failed") {
    Write-Host "Job failed."
} elseif ($jobStatus -eq "canceled") {
    Write-Host "Job was canceled."
}