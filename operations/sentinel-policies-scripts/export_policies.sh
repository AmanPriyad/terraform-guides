#!/bin/bash
# This script exports all policies from the specified organization
# of the specified TFE server to the current directory

# Make sure TFE_TOKEN and TFE_ORG environment variables are set
# to owners team token and organization name for the respective
# TFE environment.

# Set address if using private Terraform Enterprise server.
# You should edit these before running.
address="app.terraform.io"
# Set organization to use
organization="$TFE_ORG"

echo "Using address: $address"
echo "Using organization: $organization"

# Retrieve list of all policies in the organization (up to 150)
policy_list_result=$(curl --header "Authorization: Bearer $TFE_TOKEN" "https://${address}/api/v2/organizations/${organization}/policies?page%5Bsize%5D=150")
#echo $policy_list_result | jq 

# Extract policy IDs
policy_ids_list=($(echo $policy_list_result | jq -r '.data[].id'))

# Extract policy names
policy_names_list=($(echo $policy_list_result | jq -r '.data[].attributes.name'))

# Extract policy enforcement modes
policy_modes_list=($(echo $policy_list_result | jq -r '.data[].attributes.enforce[].mode'))

# Extract policy code links
policy_code_links=($(echo $policy_list_result | jq -r '.data[].links.download'))

# Iterate through list of policies
echo "Iterate through the policies:"
for ((i=0;i<${#policy_names_list[@]};++i)); do
  echo "Name: ${policy_names_list[i]}.sentinel, Mode: ${policy_modes_list[i]}, Link: https://${address}${policy_code_links[i]}"
  # curl policy code
  policy_code=$(curl -L --header "Authorization: Bearer $TFE_TOKEN" "https://${address}/${policy_code_links[i]}")
  # Add enforcement mode as a comment
  policy_code="#Enforcement mode: ${policy_modes_list[i]}\n${policy_code}"
  # write code to file
  printf "${policy_code}" > ${policy_names_list[i]}.temp
  # Remove ^M from end of the file
  sed "s///g" < ${policy_names_list[i]}.temp > ${policy_names_list[i]}.sentinel
  # delete temporary file
  rm ${policy_names_list[i]}.temp
done

echo "Exported ${#policy_names_list[@]} policies"
