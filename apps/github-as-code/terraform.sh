#!/bin/bash -x
set -euo pipefail

if [ -z "${1-}" ]; then
        echo "Usage: $0 <terraform_cmd> [terraform_cmd_arguments]"
        exit 1
fi

## Project variables
PROJECT_NAME="github"

## Input variables
MAIN_CMD="$1"
shift

## Terraform files
if [ -z "${TF_IN_AUTOMATION-}" ]; then
        tf_vars_file="${PROJECT_NAME}.tfvars"
        tf_secrets_vars_file="${PROJECT_NAME}-secrets.tfvars"
else
        cp "${PROJECT_NAME}.tfvars" "${PROJECT_NAME}.auto.tfvars"
        tf_vars_file="${PROJECT_NAME}.auto.tfvars"
        tf_secrets_vars_file="${PROJECT_NAME}-secrets.auto.tfvars"
        trap "rm -f ${tf_vars_file}" EXIT SIGINT SIGTERM
fi
trap "rm -f ${tf_secrets_vars_file}" EXIT SIGINT SIGTERM

## Configuration
cmds_vars_required=("plan" "apply" "destroy" "import" "console")

## Workspace variables check
if [ ! -f "${tf_vars_file}" ]; then
        echo -e "\e[31mERROR: \"${tf_vars_file}\" not found. First create it and then run this script again.\e[0m"
        exit 1
fi

## Secrets generation (and removal on exit)
if [ -z "${GITHUB_TOKEN-}" ]; then
        echo "github_token = \"$(gh auth token)\"" >"${tf_secrets_vars_file}"
else
        echo "github_token = \"${GITHUB_TOKEN}\"" >"${tf_secrets_vars_file}"
fi

## Terraform arguments
MAIN_ARGS=""
if [[ " ${cmds_vars_required[*]} " =~ " $MAIN_CMD " ]]; then
        if [ -z "${TF_IN_AUTOMATION-}" ]; then
                MAIN_ARGS="-var-file=${tf_vars_file} -var-file=${tf_secrets_vars_file}"
        else
                MAIN_ARGS=""
        fi
fi

## Terraform execution
terraform "${MAIN_CMD}" ${MAIN_ARGS} $@
