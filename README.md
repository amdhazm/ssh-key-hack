# SSH Key Hack Script

This script automates the setup and configuration of SSH client and server on various Linux distributions, appends authorized keys from a specified URL, and creates or updates a private Gist with the current user's name and local IP address.

## Features

1. **SSH Client and Server Installation**:
    - Detects the Linux distribution and installs the necessary SSH packages.
    - Supports Debian-based, Red Hat-based, and Arch-based systems.
2. **SSH Service Management**:
    - Starts and enables the SSH service using the appropriate service management system (`systemd` or `SysVinit`).
3. **Configuration of SSH Server**:
    - Disables password authentication.
    - Enables public key authentication.
    - Configures the `AuthorizedKeysFile`.
4. **Authorized Keys Management**:
    - **Appending from URL**:
      - The script fetches SSH public keys from a specified URL and appends them to the `authorized_keys` file. This allows for dynamic management of SSH access without manual edits.
      - **Example Usage**: You can provide a URL pointing to a raw SSH public key file hosted on a server or a Gist (like GitHub Gist) containing SSH public keys.
    - **GitHub Personal Access Token**:
      - To utilize the script's feature for creating or updating a private Gist with user and local IP information, a GitHub Personal Access Token is required.
      - **Security Note**: Ensure the token has the necessary permissions to create Gists on your GitHub account. Store the token securely and avoid sharing it publicly.
