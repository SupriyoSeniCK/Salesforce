# --------------------------------------------------------------------------------------------------------------
# Description : The purpose of this shell script is to get the PMD executed for code quality validation
# Author : Kiranmoy Pradhan
# Date : 12/12/2023
# Last Modified By: Supriyo Seni
# --------------------------------------------------------------------------------------------------------------

# Function to read the CSV content and print classname, PMD error, and error description for each issue
showPmdIssues() {
    local csvFile="$1"
    tail -n +2 "$csvFile" | while IFS=, read -r _ _ _ classPath lineNumber _ pmdError errorDescription _; do
        local className=$(basename "$classPath")
        echo "ClassName: \"$className"
        echo "PMD Error: $pmdError"
        echo "Line Number: $lineNumber"
        echo "Error Description: $errorDescription"
        echo "---------------------------------------------------------------------------------------------------"
    done
}

displayPmdErrorsForModifiedApexClass() {
    # Arguments: 
    # $1 - Path to the modified PMD report
    # $2 - Path to the base (before modifications) PMD report
    local pmdReportPathModified="$1"
    local pmdReportPathModifiedBase="$2"
    local previousClassName=""
    local validationFailed=0

    # Skip the first line (header) and loop through each line of the modified PMD report
    tail -n +2 "$pmdReportPathModified" | while IFS=, read -r _ _ _ classPath lineNumber _ pmdError errorDescription _; do
        # Extract the class name from the class path
        local className=$(basename "$classPath")
        # Check if the class has changed from the previous one
        if [[ "$previousClassName" != "$className" ]]; then
            # Count occurrences of the class name in the base and modified PMD reports
            local pmdCountInBase=$(grep -o "$className" "$pmdReportPathModifiedBase" | wc -l)
            local pmdCountInCurrent=$(grep -o "$className" "$pmdReportPathModified" | wc -l)
            echo "Class: \"$className, PMD Errors before changes: $pmdCountInBase, PMD Errors after changes: $pmdCountInCurrent"
            # Check if the PMD counts in current changes is greater than the existing PMD counts
            if [ "$pmdCountInCurrent" -gt "$pmdCountInBase" ]; then
                echo "---------------------------------------------------------------------------------------------------"
                echo "              VALIDATION FAILED: PMD error count increased after new changes                       "
                echo "---------------------------------------------------------------------------------------------------"
                echo "Class: \"$className, PMD Errors before changes: $pmdCountInBase, PMD Errors after changes: $pmdCountInCurrent"
                echo "---------------------------------------------------------------------------------------------------"
                validationFailed=1
            fi
        fi
        
        # Update the previous class name for the next iteration
        previousClassName="$className"
    done
    # Check if validation failed and exit after processing all lines
    if [[ "$validationFailed" == "1" ]]; then
        exit 1
    fi
}

displayPmdErrorsForNewApexClass() {
    # Arguments: 
    # $1 - Path to the new PMD report
    local pmdReportPathNew="$1"
    local previousClassName=""
    local validationFailed=0

    # Skip the first line (header) and loop through each line of the modified PMD report
    tail -n +2 "$pmdReportPathNew" | while IFS=, read -r _ _ _ classPath lineNumber _ pmdError errorDescription _; do
        # Extract the class name from the class path
        local className=$(basename "$classPath")
        # Check if the class has changed from the previous one
        if [[ "$previousClassName" != "$className" ]]; then           
            local pmdCount=$(grep -o "$className" "$pmdReportPathNew" | wc -l)
            echo "---------------------------------------------------------------------------------------------------"
            echo "         VALIDATION FAILED: PMD Error Found in Apex Class: \"$className                            "
            echo "---------------------------------------------------------------------------------------------------"
            echo "Class: \"$className, PMD Error Count: $pmdCount"
            echo "---------------------------------------------------------------------------------------------------"
            validationFailure=1
        fi
        # Update the previous class name for the next iteration
        previousClassName="$className"
    done
    # Check if validation failed and exit after processing all lines
    if [[ "$validationFailed" == "1" ]]; then
        exit 1
    fi
}

# Function to execute PMD scan and display results
executeScannerAndShowResult() {
    local pmdRulePath="cicd-utils/pmd-util/pmd-rule/pmdRules.xml"
    local scanEngineName="pmd"
    local reportFileType="csv"
    local newApexClasses="$1"
    local modifiedApexClasses="$2"
    local modifiedBaseApexClasses="$3"
    local pmdReportPathNew="pipeline-artifacts/pmd-results-new.csv"
    local pmdReportPathModified="pipeline-artifacts/pmd-results-modified.csv"
    local pmdReportPathModifiedBase="pipeline-artifacts/pmd-results-modified-base.csv"
    local baseBranch

    # Execute the PMD scanner command for new Apex classes if they exist
    if [[ -n "$newApexClasses" ]]; then
        sf scanner:run --engine "$scanEngineName" --format "$reportFileType" --pmdconfig "$pmdRulePath" \
                       --outfile "$pmdReportPathNew" --target "$newApexClasses" --normalize-severity
        echo "---------------------------------------------------------------------------------------------------"
        echo "|                           Static Code Scan (PMD) Report for New Apex Classes                    |"
        echo "---------------------------------------------------------------------------------------------------"
        showPmdIssues "$pmdReportPathNew"
        if [[ "$PMD_VALIDATION" == "ON" ]]; then
            echo "Validating PMD Errors for New Apex Classes............."
            
            # Call the displayPmdErrorsForModifiedApexClass function for new apex classes PMD validation
            displayPmdErrorsForNewApexClass "$pmdReportPathNew"
            if [[ $? -ne 0 ]]; then
                exit 1
            fi
        fi
    fi

    # Execute the PMD scanner command for modified Apex classes if they exist
    if [[ -n "$modifiedApexClasses" ]]; then
        sf scanner:run --engine "$scanEngineName" --format "$reportFileType" --pmdconfig "$pmdRulePath" \
                       --outfile "$pmdReportPathModified" --target "$modifiedApexClasses" --normalize-severity
        echo "---------------------------------------------------------------------------------------------------"
        echo "|                      Static Code Scan (PMD) Report for Modified Apex Classes                    |"
        echo "---------------------------------------------------------------------------------------------------"
        showPmdIssues "$pmdReportPathModified"

        if [[ "$PMD_VALIDATION" == "ON" ]]; then
            # Get PMD report of apex classes from the Base Branch
            baseBranch=$(defineBaseBranch)
            # Switch to the base branch
            git checkout "$baseBranch"
            sf scanner:run --engine "$scanEngineName" --format "$reportFileType" --pmdconfig "$pmdRulePath" \
                       --outfile "$pmdReportPathModifiedBase" --target "$modifiedBaseApexClasses" --normalize-severity
            # Switch back to the current branch
            git checkout -

            # Comparing PMD error counts between modified and base reports
            echo "Comparing PMD error counts for modified apex classes..."
            
            # Call the displayPmdErrors function for modified apex classes PMD reports
            displayPmdErrorsForModifiedApexClass "$pmdReportPathModified" "$pmdReportPathModifiedBase"
            if [[ $? -ne 0 ]]; then
                exit 1
            fi
        fi
    fi
}

# Function to handle new and modified Apex class PMD errors
handleApexClassPmdErrors() {
    local classesFolderPath="force-app/main/default/classes"
    local triggerFolderPath="force-app/main/default/triggers"
    local forceAppMainFolderPath="changed-sources/force-app/main/default"
    local baseBranch
    local SPECIFIED_APEX_CLASSES=""
    local newApexClasses=""
    local modifiedApexClasses=""
    local modifiedBaseApexClasses=""
    local sfdxPath="force-app/main/default"

    baseBranch=$(defineBaseBranch)
    if [[ $? -ne 0 ]]; then
        echo "Error determining base branch."
        exit 1
    fi

    # Get the list of changed Apex classes
    if [[ -d "$classesFolderPath" ]]; then
        SPECIFIED_APEX_CLASSES=$(git diff HEAD "$baseBranch" --name-only "$classesFolderPath")
    fi
    if [[ -d "$triggerFolderPath" ]]; then
        # Append the result of git diff only if SPECIFIED_APEX_CLASSES is not empty
        changedTriggerClasses=$(git diff HEAD "$baseBranch" --name-only "$triggerFolderPath")
        if [[ -n "$changedTriggerClasses" ]]; then
            if [[ -n "$SPECIFIED_APEX_CLASSES" ]]; then
                SPECIFIED_APEX_CLASSES+=" $changedTriggerClasses"
            else
                SPECIFIED_APEX_CLASSES="$changedTriggerClasses"
            fi
        fi
    fi

    # Process each class
    for className in $SPECIFIED_APEX_CLASSES; do
        if [[ "$className" == *.cls ]]; then
            # Removing prefixes and postfixes from the name so that we can get the corresponding test class
            className=${className#*force-app/main/default/classes/}
            className=${className#*force-app/main/default/triggers/}
            className=${className%%.*}
            baseClassPath="$sfdxPath/classes/${className}.cls"
            changedSourceClassPath="$forceAppMainFolderPath/classes/${className}.cls"
            # Separate new and modified apex classes
            if git ls-tree -r "$baseBranch" --name-only | grep -q "$baseClassPath"; then
                modifiedApexClasses+="$changedSourceClassPath,"
                modifiedBaseApexClasses+="$baseClassPath,"
            else
                newApexClasses+="$changedSourceClassPath,"
            fi
        fi
    done

    # Remove trailing commas
    newApexClasses=${newApexClasses%,}
    modifiedApexClasses=${modifiedApexClasses%,}
    modifiedBaseApexClasses=${modifiedBaseApexClasses%,}
    # Execute scanner and check for errors
    executeScannerAndShowResult "$newApexClasses" "$modifiedApexClasses" "$modifiedBaseApexClasses"
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
handleApexClassPmdErrors
