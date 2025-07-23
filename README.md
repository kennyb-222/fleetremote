# FleetRemote

FleetRemote is a wrapper around the `fleetctl` command-line tool that simplifies interactions with remote hosts managed by Fleet. It allows users to run commands interactively on a specified host, similar to how SSH works, but through Fleet. This tool enhances the ease of interacting with hosts remotely.

FleetRemote works on macOS and Linux platforms. **Windows is not supported**.

## Features
- **Interactive Command Execution**: Run commands interactively on remote hosts via Fleet.
- **Host Identification**: Connect to hosts using UUID, Serial Number, or Display Name.
- **Session Management**: Execute commands during a session and quit when finished.
- **Portable**: Use the script directly without installation or install it system-wide for easier access.

## Requirements

### fleetctl Installation and Configuration

FleetRemote relies on `fleetctl`, the official command-line tool for interacting with Fleet. You must have `fleetctl` installed and configured before using FleetRemote.

1. **Install `fleetctl`**:
   - Download the latest version of `fleetctl` from the [FleetDM GitHub Releases](https://github.com/fleetdm/fleet/releases).

2. **Configure `fleetctl`**:
   Ensure that `fleetctl` is configured with your Fleet server URL and API token. This allows the tool to authenticate and communicate with the Fleet server.

   Example configuration:
   ```bash
   fleetctl config set --address https://your-fleet-server-url
   fleetctl config set --token YOUR_API_TOKEN
   ```

   Replace `https://your-fleet-server-url` with your actual Fleet server URL and `YOUR_API_TOKEN` with the API token from your Fleet account. You can find this token in the Fleet server's UI under your user profile settings.

3. **Verify Fleetctl Installation**:
   After configuring `fleetctl`, verify the installation by running:
   ```bash
   fleetctl get hosts
   ```
   This command should return the list of hosts registered with your Fleet server. If it doesn't, revisit the configuration steps.


## Installation

FleetRemote can be installed system-wide or used as a portable script, depending on your preference.

### 1. System-wide Installation

You can install FleetRemote to `/usr/local/bin/` to make it available globally on your system.

1. **Install FleetRemote**:
   Run the following command to install the script:
   ```bash
   sudo ./fleetremote.sh install
   ```

   This command will:
   - Copy the script to `/usr/local/bin/fleetremote`
   - Set the necessary permissions

2. **Run FleetRemote**:
   After installation, you can run FleetRemote from anywhere on your system:
   ```bash
   fleetremote
   ```

### 2. Uninstallation

To remove FleetRemote from your system, run:
```bash
sudo ./fleetremote.sh uninstall
```
This will delete fleetremote from `/usr/local/bin/`.

### 3. Portable Usage

If you prefer not to install FleetRemote globally, you can use it portably by running the script directly without installation:
```bash
./fleetremote.sh
```
This method allows you to use FleetRemote from its current directory without modifying system paths.

## Usage

Once FleetRemote is installed or used portably, it provides an interactive interface to manage remote hosts through Fleet. The workflow is simple and efficient.

### 1. Launch FleetRemote

You can launch FleetRemote by running the following command (either globally or portably, depending on how you installed it):

```bash
fleetremote
```
or
```bash
./fleetremote.sh
```

### 2. Connecting to a Host

FleetRemote allows you to connect to a host using its **Serial Number**, **UUID**, or **Display Name**. When prompted, enter one of these identifiers:

```bash
Enter the target host identifier (Serial, UUID, or Display Name): <your-identifier>
```

FleetRemote will automatically resolve the identifier to a UUID using the Fleet API and will establish a connection to the specified host.

### 3. Interactive Command Execution

Once the connection is established, you can run commands interactively on the host. For example:

```bash
fleetctl@<host-identifier>> hostname
HOSTNAME: <your-host-name>
```
- **Command History**: You can use the **up** and **down arrow keys** to navigate through the history of commands you have previously executed within the current session. This makes it easier to repeat or modify previous commands without typing them again.
You can continue running commands on the host in this interactive session.

### 4. Exiting the Session

To end your session, type `quit` or `exit`:

```bash
fleetctl@<host-identifier>> quit
```

This will close the connection to the host and end the interactive session.

### Example Workflow

Here’s an example of how you might use FleetRemote to connect to a host and run commands:

```bash
$ fleetremote
Running FleetRemote version: 1.0.0
Connected to Fleet server at: https://your-fleet-server-url
Enter the target host identifier (Serial, UUID, or Display Name): ABC123456789
Resolved UUID for ABC123456789 is 0C544D11-87ED-540A-832E-076C807206AE.
Type 'quit' when done.

fleetctl@ABC123456789> hostname
HOSTNAME: ABC123456789

fleetctl@ABC123456789> uptime
UPTIME: 12 days, 5 hours

fleetctl@ABC123456789> quit
Finished running commands on ABC123456789.
```



## Error Handling

FleetRemote will notify you of any issues during the session:

- **Invalid Identifier**: If the provided identifier cannot be resolved, you will see an error message:
  ```bash
  ERROR: Could not resolve UUID for <identifier>. Exiting.
  ```

- **Host Offline**: If the target host is not online, you will be notified:
  ```bash
  ERROR: Target host <identifier> is not currently online. Exiting.
  ```

- **fleetctl Not Installed**: If `fleetctl` is not installed or improperly configured, FleetRemote will exit with one of the following errors:
  ```bash
  ERROR: fleetctl is not installed. Please install it from https://github.com/fleetdm/fleet/releases
  ```
  or
    ```bash
  ERROR: `fleetctl get config` cmd failure. Exiting.
  ```

## Contributing

Contributions to FleetRemote are welcome! To contribute:

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/my-feature`).
3. Commit your changes (`git commit -am 'Add my feature'`).
4. Push to the branch (`git push origin feature/my-feature`).
5. Create a new pull request.

If you find any bugs or have feature requests, please open an issue.
