# --------------------------------------------------------------------------------------------------------------
# Description : The purpose of this shell script is to get the PMD executed for code quality validation
# Author : Kiranmoy Pradhan
# Date : 12/12/2023
# Last Modified By: Supriyo Seni
# --------------------------------------------------------------------------------------------------------------

#Global variable
APEX_VALIDATION_FAILED="NO"

# Function to read the CSV content and print classOrTriggerName, PMD error, and error description for each issue
showPmdIssues() {
    local csvFile="$1"
    tail -n +2 "$csvFile" | while IFS=, read -r _ _ _ classPath lineNumber _ pmdError errorDescription _; do
        local classOrTriggerName=$(basename "$classPath")
        echo "class Name: \"$classOrTriggerName"
        echo "PMD Error: $pmdError"
        echo "Line Number: $lineNumber"
        echo "Error Description: $errorDescription"
        echo "---------------------------------------------------------------------------------------------------"
    done
}

displayPmdErrorsForModifiedApexComponents() {
    # Arguments: 
    # $1 - Path to the modified PMD report
    # $2 - Path to the base (before modifications) PMD report
    # $3 - All modified apex components (classes and triggers)
    local pmdReportPathModified="$1"
    local pmdReportPathModifiedBase="$2"
    local modifiedApexComponents="$3"

    # Set Internal Field Separator (IFS) to comma
    IFS=','

    # Loop through each path
    for path in $modifiedApexComponents; do
        # Extract the class name
        local classOrTriggerName=$(basename "$path")
        # Count occurrences of the class name in the base and modified PMD reports
        local pmdCountInBase=$(grep -o "/$classOrTriggerName\"" "$pmdReportPathModifiedBase" | wc -l)
        local pmdCountInCurrent=$(grep -o "/$classOrTriggerName\"" "$pmdReportPathModified" | wc -l)
        # Check if the PMD counts in current changes is greater than the existing PMD counts
        if [ "$pmdCountInCurrent" -gt "$pmdCountInBase" ]; then
            echo "---------------------------------------------------------------------------------------------------"
            echo "              VALIDATION FAILED: PMD error count increased after new changes                       "
            printf "%-55s | %-40s | %-40s\n" "Class: \"$classOrTriggerName\"" "PMD violations before changes : $pmdCountInBase" "PMD violations after changes : $pmdCountInCurrent"
            echo "---------------------------------------------------------------------------------------------------"
            # validation failed
            APEX_VALIDATION_FAILED="YES"
        else
            printf "%-55s | %-40s | %-40s\n" "Class: \"$classOrTriggerName\"" "PMD violations before changes : $pmdCountInBase" "PMD violations after changes : $pmdCountInCurrent"
        fi
    done

    # Reset IFS to default
    unset IFS
}

displayPmdErrorsForNewApexComponents() {
    # Arguments: 
    # $1 - Path to the new PMD report
    # $2 - new apex components (classes and triggers)
    local pmdReportPathNew="$1"
    local newApexComponents="$2"

    # Set Internal Field Separator (IFS) to comma
    IFS=','

    # Loop through each path
    for path in $newApexComponents; do
        # Extract the class name
        local classOrTriggerName=$(basename "$path")
        # PMD count
        local pmdCount=$(grep -o "/$classOrTriggerName\"" "$pmdReportPathNew" | wc -l)
        # Check if the pmd count is greated than zero
        if [[ "$pmdCount" -gt 0 ]]; then           
            echo "---------------------------------------------------------------------------------------------------"
            echo "         VALIDATION FAILED: PMD Error Found in Apex Class: \"$classOrTriggerName\"                  "
            printf "%-55s | %-40s\n" "Class: \"$classOrTriggerName\"" "PMD violations : $pmdCount"
            echo "---------------------------------------------------------------------------------------------------"
            # validation failed
            APEX_VALIDATION_FAILED="YES"
        fi
    done
    
    # Reset IFS to default
    unset IFS
}

# Function to execute PMD scan and display results
executeScannerAndShowResult() {
    local pmdRulePath="cicd-utils/pmd-util/pmd-rule/pmdRules.xml"
    local scanEngineName="pmd"
    local reportFileType="csv"
    local newApexComponents="$1"
    local modifiedApexComponents="$2"
    local baseApexComponents="$3"
    local pmdReportPathNew="pipeline-artifacts/pmd-results-new.csv"
    local pmdReportPathModified="pipeline-artifacts/pmd-results-modified.csv"
    local pmdReportPathModifiedBase="pipeline-artifacts/pmd-results-modified-base.csv"
    local baseBranch

    # Execute the PMD scanner command for new Apex classes if they exist
    if [[ -n "$newApexComponents" ]]; then
        sf scanner:run --engine "$scanEngineName" --format "$reportFileType" --pmdconfig "$pmdRulePath" \
                       --outfile "$pmdReportPathNew" --target "$newApexComponents" --normalize-severity
        echo "---------------------------------------------------------------------------------------------------"
        echo "|                           Static Code Scan (PMD) Report for New Apex Classes                    |"
        echo "---------------------------------------------------------------------------------------------------"
        showPmdIssues "$pmdReportPathNew"
    fi

    # Execute the PMD scanner command for modified Apex classes if they exist
    if [[ -n "$modifiedApexComponents" ]]; then
        sf scanner:run --engine "$scanEngineName" --format "$reportFileType" --pmdconfig "$pmdRulePath" \
                       --outfile "$pmdReportPathModified" --target "$modifiedApexComponents" --normalize-severity
        echo "---------------------------------------------------------------------------------------------------"
        echo "|                      Static Code Scan (PMD) Report for Modified Apex Classes                    |"
        echo "---------------------------------------------------------------------------------------------------"
        showPmdIssues "$pmdReportPathModified"
    fi

    # Execute this if PMD_VALIDATION from repository settings in ON
    if [[ "$PMD_VALIDATION" == "ON" ]]; then
        if [[ -n "$modifiedApexComponents" ]]; then
            # Get PMD report of apex classes from the Base Branch
            baseBranch=$(defineBaseBranch)
            # Switch to the base branch
            git checkout "$baseBranch"
            # Run scanner to generate PMD report for the modified classes in the targer branch
            sf scanner:run --engine "$scanEngineName" --format "$reportFileType" --pmdconfig "$pmdRulePath" \
                        --outfile "$pmdReportPathModifiedBase" --target "$baseApexComponents" --normalize-severity
            # Switch back to the current branch
            git checkout -

            # Comparing PMD error counts between modified and base reports
            echo "Validating PMD Errors for Modified Apex Classes............."
            
            # Call the displayPmdErrors function for modified apex classes PMD reports
            displayPmdErrorsForModifiedApexComponents "$pmdReportPathModified" "$pmdReportPathModifiedBase" "$modifiedApexComponents"
        fi

        if [[ -n "$newApexComponents" ]]; then
            echo "Validating PMD Errors for New Apex Classes............."
            # Call the displayPmdErrors function for new apex classes PMD validation
            displayPmdErrorsForNewApexComponents "$pmdReportPathNew" "$newApexComponents"
        fi    
        # Check if PMD validation failed and exit
        if [[ "$APEX_VALIDATION_FAILED" == "YES" ]]; then
            exit 1
        fi
    fi
}

# Function to handle new and modified Apex class PMD errors
handleApexPmdErrors() {
    local classesFolderPath="force-app/main/default/classes"
    local triggerFolderPath="force-app/main/default/triggers"
    local forceAppMainFolderPath="changed-sources/force-app/main/default"
    local baseBranch
    local allApexComponents=""
    local newApexComponents=""
    local modifiedApexComponents=""
    local baseApexComponents=""
    local sfdxPath="force-app/main/default"

    baseBranch=$(defineBaseBranch)
    if [[ $? -ne 0 ]]; then
        echo "Error determining base branch."
        exit 1
    fi

    # Get the list of changed Apex classes from the branch
    if [[ -d "$classesFolderPath" ]]; then
        allApexComponents=$(git diff HEAD "$baseBranch" --name-only "$classesFolderPath")
    fi
    # Add the triggers as well if present
    if [[ -d "$triggerFolderPath" ]]; then
        # Append the result of git diff only
        changedTriggerClasses=$(git diff HEAD "$baseBranch" --name-only "$triggerFolderPath")
        if [[ -n "$changedTriggerClasses" ]]; then
            if [[ -n "$allApexComponents" ]]; then
                allApexComponents+=" $changedTriggerClasses"
            else
                allApexComponents="$changedTriggerClasses"
            fi
        fi
    fi

    # Process each class or trigger
    for classOrTriggerName in $allApexComponents; do
        if [[ "$classOrTriggerName" == *.cls ]]; then
            # Removing prefixes and postfixes from the name so that we can get class name only
            classOrTriggerName=${classOrTriggerName#*force-app/main/default/classes/}
            classOrTriggerName=${classOrTriggerName#*force-app/main/default/triggers/}
            classOrTriggerName=${classOrTriggerName%%.*}
            # build the class path for the base branch
            baseComponentPath="$sfdxPath/classes/${classOrTriggerName}.cls"
            # build the class path for the current/changed-source branch 
            changedSourcePath="$forceAppMainFolderPath/classes/${classOrTriggerName}.cls"
            # Separate new and modified apex classes
            if git ls-tree -r "$baseBranch" --name-only | grep -q "$baseComponentPath"; then
                modifiedApexComponents+="$changedSourcePath,"
                baseApexComponents+="$baseComponentPath,"
            else
                newApexComponents+="$changedSourcePath,"
            fi
        elif [[ "$classOrTriggerName" == *.trigger ]]; then
            # Removing prefixes and postfixes from the name so that we can get trigger name only
            classOrTriggerName=${classOrTriggerName#*force-app/main/default/classes/}
            classOrTriggerName=${classOrTriggerName#*force-app/main/default/triggers/}
            classOrTriggerName=${classOrTriggerName%%.*}
            # build the trigger path for the base branch
            baseComponentPath="$sfdxPath/triggers/${classOrTriggerName}.trigger"
            # build the trigger path for the current/changed-source branch 
            changedSourcePath="$forceAppMainFolderPath/triggers/${classOrTriggerName}.trigger"
            # Separate new and modified apex triggers and append them in required variables
            if git ls-tree -r "$baseBranch" --name-only | grep -q "$baseComponentPath"; then
                modifiedApexComponents+="$changedSourcePath,"
                baseApexComponents+="$baseComponentPath,"
            else
                newApexComponents+="$changedSourcePath,"
            fi
        fi
    done

    # Remove trailing commas
    newApexComponents=${newApexComponents%,}
    modifiedApexComponents=${modifiedApexComponents%,}
    baseApexComponents=${baseApexComponents%,}
    # Execute scanner and check for errors and show results
    executeScannerAndShowResult "$newApexComponents" "$modifiedApexComponents" "$baseApexComponents"
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
}

# Function to define the base branch based on $WORKFLOW_TYPE
defineBaseBranch() {
    if [[ "$WORKFLOW_TYPE" == "DEPLOYMENT" ]]; then
        echo "HEAD^"
    elif [[ "$WORKFLOW_TYPE" == "PRVALIDATION" ]]; then
        echo "origin/$BITBUCKET_PR_DESTINATION_BRANCH"
    else
        echo "Invalid WORKFLOW_TYPE specified"
        return 1
    fi
}

# Main script execution starts here
handleApexPmdErrors
