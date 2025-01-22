# --------------------------------------------------------------------------------------------------------------
# Description : The purpose of this shell script is to get the org authenticate using secret url.
# Author : Kiranmoy Pradhan
# Date : 12/12/2023
# --------------------------------------------------------------------------------------------------------------

# Define a function to login to the Salesforce org using SFDX URL
loginToSalesforceOrg() {
    # Define the --from parameter based on $WORKFLOW_TYPE
    if [[ "$WORKFLOW_TYPE" == "DEPLOYMENT" ]]; then
        echo "------------------------------------------------------------------------------------------------------------"
        echo "|                         Authenticate with Salesforce org [$AUTH_ORG_ALIAS]                               |"
        echo "------------------------------------------------------------------------------------------------------------"
        # If workflow type is deployment then get the secret url path of the destination org
        local sfdxUrlFile="./CI_SFDX_URL.txt"
        echo "${SECRET_URL_PATH}" > "$sfdxUrlFile"
        sf org login sfdx-url --sfdx-url-file "$sfdxUrlFile" --set-default --alias "${AUTH_ORG_ALIAS}"
    elif [[ "$WORKFLOW_TYPE" == "PRVALIDATION" ]]; then
        # If the destination Branch is dev
        if [[ "$BITBUCKET_PR_DESTINATION_BRANCH" == "dev" ]]; then
            echo "------------------------------------------------------------------------------------------------------------"
            echo "|                         Authenticate with Salesforce org [$DEV_AUTH_ORG_ALIAS]                                |"
            echo "------------------------------------------------------------------------------------------------------------"

            local sfdxUrlFile="./CI_SFDX_URL.txt"
            echo "${DEV_SECRET_URL_PATH}" > "$sfdxUrlFile"
            sf org login sfdx-url --sfdx-url-file "$sfdxUrlFile" --set-default --alias "${DEV_AUTH_ORG_ALIAS}"
        # If the destination Branch is uat
        elif [[ "$BITBUCKET_PR_DESTINATION_BRANCH" == "uat" ]]; then
            echo "------------------------------------------------------------------------------------------------------------"
            echo "|                         Authenticate with Salesforce org [$UAT_AUTH_ORG_ALIAS]                               |"
            echo "------------------------------------------------------------------------------------------------------------"
            local sfdxUrlFile="./CI_SFDX_URL.txt"
            echo "${UAT_SECRET_URL_PATH}" > "$sfdxUrlFile"
            sf org login sfdx-url --sfdx-url-file "$sfdxUrlFile" --set-default --alias "${UAT_AUTH_ORG_ALIAS}"
        # If the destination Branch is prprod
        elif [[ "$BITBUCKET_PR_DESTINATION_BRANCH" == "preprod" ]]; then
            echo "------------------------------------------------------------------------------------------------------------"
            echo "|                         Authenticate with Salesforce org [$PREPROD_AUTH_ORG_ALIAS]                               |"
            echo "------------------------------------------------------------------------------------------------------------"
            local sfdxUrlFile="./CI_SFDX_URL.txt"
            echo "${PREPROD_SECRET_URL_PATH}" > "$sfdxUrlFile"
            sf org login sfdx-url --sfdx-url-file "$sfdxUrlFile" --set-default --alias "${PREPROD_AUTH_ORG_ALIAS}"
        # If the destination Branch is master
        elif [[ "$BITBUCKET_PR_DESTINATION_BRANCH" == "master" ]]; then
            echo "------------------------------------------------------------------------------------------------------------"
            echo "|                         Authenticate with Salesforce org [$PROD_AUTH_ORG_ALIAS]                               |"
            echo "------------------------------------------------------------------------------------------------------------"
            local sfdxUrlFile="./CI_SFDX_URL.txt"
            echo "${PROD_SECRET_URL_PATH}" > "$sfdxUrlFile"
            sf org login sfdx-url --sfdx-url-file "$sfdxUrlFile" --set-default --alias "${PROD_AUTH_ORG_ALIAS}"
        else
            echo "Invalid PR_DESTINATION_BRANCH"
            return 1
        fi
    else
        echo "Invalid WORKFLOW_TYPE specified"
        return 1
    fi

}

# Init Salesforce authentication
loginToSalesforceOrg