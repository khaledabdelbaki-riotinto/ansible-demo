#!/bin/bash

# Prompt for testVar if not provided as an argument
if [ -z "$testVar" ]; then
    read -p "Enter the test variable: " testVar
fi


# API base URL and job template ID
baseUrl="https://aap.corp.riotinto.org/api/controller/v2"
jobTemplateId="2906"  # Replace with your job template ID

# Prompt for username and password
read -p "Enter your Ansible Automation Platform username: " username
read -s -p "Enter your Ansible Automation Platform password: " password
echo

# Encode credentials for Basic Authentication
authHeader=$(echo -n "${username}:${password}" | base64)

# Prepare extra_vars JSON
extraVars="{\"test_var\":\"$testVar\"}"
body="{\"extra_vars\":$extraVars}"

# Launch the job template
launchUrl="$baseUrl/job_templates/$jobTemplateId/launch/"
response=$(curl -sk -X POST "$launchUrl" \
    -H "Content-Type: application/json" \
    -H "Authorization: Basic $authHeader" \
    -d "$body")

# Extract job ID
jobId=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
if [ -z "$jobId" ]; then
    echo "Failed to launch job. Response:"
    echo "$response"
    exit 1
fi

echo "Ansible job launched successfully. Job ID: $jobId"
echo "Checking the job status every 30 seconds..."

jobStatusUrl="$baseUrl/jobs/$jobId/"
jobStatus=""

while true; do
    jobStatusResponse=$(curl -sk -X GET "$jobStatusUrl" \
        -H "Authorization: Basic $authHeader")
    jobStatus=$(echo "$jobStatusResponse" | grep -o '"status":"[^"]*"' | cut -d: -f2 | tr -d '"')

    echo "Job Status: $jobStatus"

    if [[ "$jobStatus" == "successful" ]]; then
        echo "Job completed successfully."
        break
    elif [[ "$jobStatus" == "failed" ]]; then
        echo "Job failed."
        break
    elif [[ "$jobStatus" == "canceled" ]]; then
        echo "Job was canceled."
        break
    else
        sleep 30
    fi
done
