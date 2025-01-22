# --------------------------------------------------------------------------------------------------------------
# Description : The purpose of this shell script is to make the package ready for deployment by validation.
# Author : Kiranmoy Pradhan
# Date : 12/12/2023
# --------------------------------------------------------------------------------------------------------------

# Define a function for delta check-only deployment
performDeltaCheckOnlyDeployment() {

    echo "---------------------------------------------------------------------------------------------------"
    echo "|                                      Component Validation                                       |"
    echo "---------------------------------------------------------------------------------------------------"

    local packageXmlFilePath="changed-sources/package/package.xml"
    local runTestClassesFilePath="./cicd-utils/testclass-util/runTestClasses.txt"
    local deployOrgFilePath="./DEPLOY_ORG.txt"
    local SPECIFIED_TEST_CLASS="AloricaSFTPDocGenTest"

    # Checking if any metadata changes are in package.xml
    if grep -q '<types>' $packageXmlFilePath; then
        # Define how to validate components based on $WORKFLOW_TYPE
        if [[ "$WORKFLOW_TYPE" == "DEPLOYMENT" ]]; then
            if grep -q '<name>ApexClass</name>' $packageXmlFilePath; then
                # Initiating async deployment with RunSpecifiedTests.
                sf project deploy start -o $AUTH_ORG_ALIAS -x $packageXmlFilePath -l RunSpecifiedTests -t $(cat $runTestClassesFilePath) --verbose --dry-run --async | tee $deployOrgFilePath
            else
                # Initiating async deployment with the specified test class.
                sf project deploy start -o $AUTH_ORG_ALIAS -x $packageXmlFilePath -l RunSpecifiedTests -t $SPECIFIED_TEST_CLASS --verbose --dry-run --async | tee $deployOrgFilePath
            fi
        elif [[ "$WORKFLOW_TYPE" == "PRVALIDATION" ]]; then
            # If the destination Branch is dev
            if [[ "$BITBUCKET_PR_DESTINATION_BRANCH" == "dev" ]]; then
                if grep -q '<name>ApexClass</name>' $packageXmlFilePath; then
                    # Initiating async deployment with RunSpecifiedTests.
                    sf project deploy start -o $DEV_AUTH_ORG_ALIAS -x $packageXmlFilePath -l RunSpecifiedTests -t $(cat $runTestClassesFilePath) --verbose --dry-run --async | tee $deployOrgFilePath
                else
                    # Initiating async deployment with the specified test class.
                    sf project deploy start -o $DEV_AUTH_ORG_ALIAS -x $packageXmlFilePath -l RunSpecifiedTests -t $SPECIFIED_TEST_CLASS --verbose --dry-run --async | tee $deployOrgFilePath
                fi
            # If the destination Branch is uat
            elif [[ "$BITBUCKET_PR_DESTINATION_BRANCH" == "uat" ]]; then
                if grep -q '<name>ApexClass</name>' $packageXmlFilePath; then
                    # Initiating async deployment with RunSpecifiedTests.
                    sf project deploy start -o $UAT_AUTH_ORG_ALIAS -x $packageXmlFilePath -l RunSpecifiedTests -t $(cat $runTestClassesFilePath) --verbose --dry-run --async | tee $deployOrgFilePath
                else
                    # Initiating async deployment with the specified test class.
                    sf project deploy start -o $UAT_AUTH_ORG_ALIAS -x $packageXmlFilePath -l RunSpecifiedTests -t $SPECIFIED_TEST_CLASS --verbose --dry-run --async | tee $deployOrgFilePath
                fi
            # If the destination Branch is preprod
            elif [[ "$BITBUCKET_PR_DESTINATION_BRANCH" == "preprod" ]]; then
                if grep -q '<name>ApexClass</name>' $packageXmlFilePath; then
                    # Initiating async deployment with RunSpecifiedTests.
                    sf project deploy start -o $PREPROD_AUTH_ORG_ALIAS -x $packageXmlFilePath -l RunSpecifiedTests -t $(cat $runTestClassesFilePath) --verbose --dry-run --async | tee $deployOrgFilePath
                else
                    # Initiating async deployment with the specified test class.
                    sf project deploy start -o $PREPROD_AUTH_ORG_ALIAS -x $packageXmlFilePath -l RunSpecifiedTests -t $SPECIFIED_TEST_CLASS --verbose --dry-run --async | tee $deployOrgFilePath
                fi
            # If the destination Branch is preprod
            elif [[ "$BITBUCKET_PR_DESTINATION_BRANCH" == "master" ]]; then
                if grep -q '<name>ApexClass</name>' $packageXmlFilePath; then
                    # Initiating async deployment with RunSpecifiedTests.
                    sf project deploy start -o $PROD_AUTH_ORG_ALIAS -x $packageXmlFilePath -l RunSpecifiedTests -t $(cat $runTestClassesFilePath) --verbose --dry-run --async | tee $deployOrgFilePath
                else
                    # Initiating async deployment with the specified test class.
                    sf project deploy start -o $PROD_AUTH_ORG_ALIAS -x $packageXmlFilePath -l RunSpecifiedTests -t $SPECIFIED_TEST_CLASS --verbose --dry-run --async | tee $deployOrgFilePath
                fi
            else
                echo "Invalid PR_DESTINATION_BRANCH"
                return 1
            fi
        else
            echo "Invalid WORKFLOW_TYPE specified"
            return 1
        fi        
        
        # Fetching Deploy Id from the output.
        VALIDATION_OUTPUT=$(cat $deployOrgFilePath) 
        DEPLOYMENT_STRING=${VALIDATION_OUTPUT#*Deploy ID: }
        echo $DEPLOYMENT_STRING
        FINAL_DEPLOY_ID=${DEPLOYMENT_STRING:0:18}
        echo $FINAL_DEPLOY_ID

        # Watch the deployment for validation.
        sf project deploy resume --job-id $FINAL_DEPLOY_ID --coverage-formatters cobertura --junit --results-dir "pipeline-artifacts" --verbose

        DEPLOY_EXIT_CODE=${PIPESTATUS[0]}
        if [ $DEPLOY_EXIT_CODE != 0 ]; then
            exit $DEPLOY_EXIT_CODE;
        fi
    else
        echo "Empty package.xml file."
        exit 0
    fi
}

# Initiate component validation
performDeltaCheckOnlyDeployment