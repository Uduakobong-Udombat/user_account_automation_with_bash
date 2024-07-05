#!/bin/bash
# automating user account creation

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}
# Input file (usernames and groups)
input_file="$1"


# create log file 
touch /var/log/user_management.log
# Log file
log_file="/var/log/user_management.log"
chmod 600 "$log_file"


# create secure directory
sudo mkdir -p /var/secure

# create password file
touch /var/secure/user_passwords.txt
# Secure password storage file
password_file="/var/secure/user_passwords.txt"
chmod 600 "$password_file"



# Function to generate a random password
generate_password() {
    tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 12
}


# Read input file line by line
while IFS=';' read -r username groups; do
    # Create groups if they don't exist
    for group in $(echo "$groups" | tr ',' ' '); do
      groupadd "$group" 2>/dev/null || echo "Group $group created"
    done

   
    # Create user
    if ! getent passwd "$username" > /dev/null 2>&1; then
      useradd -m -U "$username" -G "$groups" 2>/dev/null || echo "User $username created"
    else
      echo "User $username already exists"
    fi
   
   # Set password
   
   password=$(generate_password)
   if ! echo "$username:$password" | chpasswd; then
        echo "Failed to set password for user $username"
   else
        echo "$username,$password" >> /var/secure/user_passwords.txt
        echo "User $username created with password: $password"
   fi
    # Add user to additional groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo "$group" | xargs)
        if ! getent group "$group" > /dev/null 2>&1; then
            groupadd "$group"
            log_message "Created group $group"
        fi
        usermod -a -G "$group" "$username"
        if [ $? -eq 0 ]; then
            log_message "Added user $username to group $group"
        else
            log_message "Failed to add user $username to group $group"
        fi
    done

    # Log actions
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Created user $username with groups: $groups" >> "$log_file"

    # Store password securely
    echo "$username:$password" >> "$password_file"
done < "$input_file"
