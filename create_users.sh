#!/bin/bash
# automating user account creation

# Input file (usernames and groups)
input_file="$1"

# Log file
log_file="/var/log/user_management.log"

# Secure password storage file
password_file="/var/secure/user_passwords.txt"

# create secure directory
sudo mkdir -p /var/secure

# Function to generate a random password
generate_password() {
    
    # using 'openssl rand -base64 12’ to generate a 12-character password
    openssl rand -base64 12
}

# Read input file line by line
while IFS=';' read -r username groups; do
    # Create groups if they don't exist
    for group in $(echo "$groups" | tr ',' ' '); do
      groupadd "$group" 2>/dev/null || echo "Group $group already exists"
    done

    # Create user
    useradd -m "$username" -G "$groups" 2>/dev/null || echo "User $username already exists"

    # Set password
    password=$(generate_password)
    echo "$username:$password" | chpasswd

    # Log actions
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Created user $username with groups: $groups" >> "$log_file"

    # Store password securely
    echo "$username:$password" >> "$password_file"
done < "$input_file"
