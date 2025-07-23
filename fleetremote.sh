#!/bin/bash
# fleetremote: A wrapper around the fleetctl command-line tool for streamlined interaction.
# This script enables users to run commands interactively on a specified host through fleetctl,
# offering functionality similar to SSH.

# set environment
PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
VERSION="1.0.0"

#####################################
#            FUNCTIONS              #
#####################################

_run() {
    # Run the fleetremote program

    # Trap code
    cleanup() {
        # Save the command history
        history -w ${historyFile}
        echo "" # Added space
        echo "Exiting FleetRemote..."
        exit 1
    }

    # Catch termination
    trap cleanup SIGINT

    # Display version
    echo "Running FleetRemote version: ${VERSION}"

    # Check fleetctl
    if ! command -v fleetctl &> /dev/null; then
      echo "ERROR: fleetctl is not installed. You can install it from https://github.com/fleetdm/fleet/releases"
      exit 1
    fi

    # Fetch the server_url from fleetctl configuration
    fleetServerUrl=$(fleetctl get config 2>&1 | awk '$1 == "server_url:"' | awk '{print $2}')

    # Exit if server_url is blank
    if [ -z "${fleetServerUrl}" ]; then
      echo "ERROR: \`fleetctl get config\` cmd failure. Exiting."
      echo ""  # Added space
      exit 1
    fi

    # Display the server_url from fleetctl configuration
    echo "Connected to Fleet server at: ${fleetServerUrl}"
    echo ""  # Added space

    # Check if inputIdentifier is set (can be SERIAL, UUID, or DISPLAY_NAME)
    if [ -z "${inputIdentifier}" ]; then
      read -e -p "Enter the target host identifier (Serial, UUID, or Display Name): " inputIdentifier
    fi

    # Fetch the data for hosts from fleetctl and store in OUTPUT
    echo -n "Fetching hosts from Fleet server. This could take a minute... "

    # Start the spinner in the background
    spin='-\|/'
    while :; do
        for i in {0..3}; do
            printf "\rFetching hosts from Fleet server. This could take a minute... %s" "${spin:$i:1}"
            sleep 0.1
        done
    done &

    SPIN_PID=$!  # Capture the spinner's process ID

    # Run fleetctl command
    fleetctlOut=$(fleetctl get hosts -json 2> /dev/null)

    # Stop the spinner
    kill $SPIN_PID >/dev/null 2>&1
    wait $SPIN_PID 2>/dev/null

    # Clear the spinner and print a success message
    printf "\rFetching hosts from Fleet server. Done!                                           \n"

    # Check if the input is a valid UUID (standard UUID pattern check)
    if [[ "${inputIdentifier}" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
      # Fetch the host by UUID
      echo "Fetching host by UUID: ${inputIdentifier}..."
      uuidLines=$(echo "${fleetctlOut}" | grep "\"uuid\":\"${inputIdentifier}\"" | grep -o "\"uuid\":\"[^\"]*\"" | sed 's/.*"uuid":"//;s/"//')

    # Check if the input is a valid serial number (alphanumeric characters only)
    elif [[ "${inputIdentifier}" =~ ^[A-Z0-9]+$ ]]; then
      # Convert serial number to uppercase (as serial numbers are case-insensitive)
      inputIdentifier=$(echo "${inputIdentifier}" | tr '[:lower:]' '[:upper:]')
      echo "Fetching UUID for Serial Number: ${inputIdentifier}..."
      uuidLines=$(echo "${fleetctlOut}" | grep "\"hardware_serial\":\"${inputIdentifier}\"" | grep -o "\"uuid\":\"[^\"]*\"" | sed 's/.*"uuid":"//;s/"//')

    # Assuming it's a display name
    else
      echo "Fetching UUID for Display Name: ${inputIdentifier}..."
      uuidLines=$(echo "${fleetctlOut}" | grep "\"display_name\":\"${inputIdentifier}\"" | grep -o "\"uuid\":\"[^\"]*\"" | sed 's/.*"uuid":"//;s/"//')
    fi

    # Count the number of UUIDs found
    uuidCount=$(echo "${uuidLines}" | wc -l)

    # Exit if more than one UUID found
    if [ "${uuidCount}" -ne 1 ]; then
      echo "ERROR: Found ${uuidCount} UUIDs for the provided identifier (${inputIdentifier}). Exiting."
      echo ""  # Added space
      exit 1
    fi

    # If there's only one UUID, then assign it to the hostUuid variable.
    hostUuid=${uuidLines}

    # Exit if no UUID was found
    if [ -z "${hostUuid}" ]; then
      echo "ERROR: Could not resolve UUID for ${inputIdentifier}. Exiting."
      echo ""  # Added space
      exit 1
    fi

    echo "Resolved UUID for ${inputIdentifier} is ${hostUuid}."

    # Check if the target host is online
    deviceStatus=$(echo "${fleetctlOut}" | grep "\"uuid\":\"${hostUuid}\"" | grep -o "\"status\":\"[^\"]*\"" | sed 's/.*"status":"//;s/"//')

    # Exit if host status in Fleet is offline
    if [ "${deviceStatus}" != "online" ]; then
      echo "ERROR: Target host ${inputIdentifier} is not currently online. Exiting."
      echo ""  # Added space
      exit 1
    fi

    # Inform the user how to exit
    echo "Type 'quit' when done."
    echo ""  # Added space

    # Set and load command history for fleetremote
    historyFile=~/.fleetremote_history
    touch ${historyFile}
    history -r ${historyFile}

    while true; do
      # Prompt for the next command
      read -e -r -p "fleetctl@${inputIdentifier}> " cmd

      # Append the command to the history
      history -s "${cmd}"

      # Save the in-memory history to ${historyFile}
      history -w ${historyFile}

      # If the user types "history", display the commands in ${historyFile} with line numbers
      if [[ "${cmd}" == "history" ]]; then
        nl -w 4 -s '  ' ${historyFile}
        continue
      fi

      # If the entered command is empty, continue to the next iteration
      if [[ -z "${cmd}" ]]; then
        continue
      fi

      # Exit the loop if the user types 'quit'
      if [[ "${cmd}" == "quit" ]] || [[ "${cmd}" == "exit" ]]; then
        echo "Finished running commands on ${inputIdentifier}."
        echo ""  # Added space
        break
      fi

      # Create a temporary file for the script with .sh extension
      tmpScript=$(mktemp)
      tmpScript="${tmpScript}.sh"

      # Capture the current PATH
      currentPath=$PATH

      # Start the temporary script with `#!/bin/sh`
      echo "#!/bin/sh" > "${tmpScript}"

      # Invoke a bash subshell within the script
      echo "# Script generated by fleetremote version: ${VERSION}" >> "${tmpScript}"
      echo "bash <<'EOF'" >> "${tmpScript}"
      echo "export PATH=\"${currentPath}\"" >> "${tmpScript}"
      echo "" >> "${tmpScript}"
      echo "${cmd}" >> "${tmpScript}"
      echo "" >> "${tmpScript}"
      echo "EOF" >> "${tmpScript}"

      # Run the script using fleetctl, convert HTML entities from run-script output
      fleetctlOut=$(fleetctl run-script --script-path="${tmpScript}" --host="${hostUuid}" 2>/dev/null | perl -MHTML::Entities -pe 'decode_entities($_);')

      # Check status of fleetctl
      if [[ $? -ne 0 ]] || [[ -z "${fleetctlOut}" ]]; then
        echo "ERROR: Something went wrong. Host may be offline."
        echo ""  # Added space
      else
        # If the command was successful and "Exit code: 0" is present, parse and display the desired output
        if echo "${fleetctlOut}" | grep -q "Exit code: 0"; then
            echo "${fleetctlOut}" | awk '/--------------------/{flag=!flag; next} flag'
        else
            # Otherwise, just display the full output
            echo "${fleetctlOut}"
        fi
      fi

      # Delete the temporary script
      rm -f "${tmpScript}"
    done

    # Save the final command history
    history -w ${historyFile}

    # Exit the script with success code
    exit 0
}

_install() {
    # install the fleetremote to /usr/local/bin
    cp "$0" /usr/local/bin/fleetremote
    chmod 755 /usr/local/bin/fleetremote
    echo "FleetRemote installed to /usr/local/bin/fleetremote"
    exit 0
}

_uninstall() {
    # uninstall fleetremote
    rm -f /usr/local/bin/fleetremote
    echo "FleetRemote has been uninstalled"
    exit 0
}

#####################################
#          SCRIPT LOGIC             #
#####################################

# Ensure the script is run as root for install and uninstall
if [[ ("${1}" == "install" || "${1}" == "uninstall") && "${EUID}" -ne 0 ]]
then
    echo "This script must be run as root to perform ${1}."
    exit 1
fi

# check what arg was passed from the script, call appropriate function
if [[ "${1}" == "install" ]]
then
    # run install
    _install
elif [[ "${1}" == "uninstall" ]]
then
    # run uninstall
    _uninstall
else
    # No arguments provided or unrecognized argument
    # Run the main functionality
    _run "${@}"
fi
