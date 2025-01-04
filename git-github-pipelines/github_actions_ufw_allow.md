## Requirements

1. **Tools**:
   - `curl`
   - `jq`
   - `ufw`

   Install with:
   ```bash
   sudo apt update && sudo apt install curl jq ufw -y
   ```

2. **Permissions**:
   - Run the script with `sudo` to modify UFW rules.

## How to Use

1. **Download the Script**:
   Save the script as `update_github_ufw.sh`.

2. **Make the Script Executable**:
   ```bash
   chmod +x update_github_ufw.sh
   ```

3. **Run the Script**:
   Execute the script with superuser privileges:
   ```bash
   sudo ./update_github_ufw.sh
   ```

4. **Verify UFW Rules**:
   Check the added rules:
   ```bash
   sudo ufw status verbose
   ```

## Features

- Fetches the latest GitHub IP ranges for SSH, hooks, actions, and pages.
- Validates IP formats and updates UFW rules dynamically.
- Tags rules with the comment `GitHub SSH Allow` for easy identification.

## OPT 
- Modify the services to include (`.ssh_keys[]`, `.hooks[]`, `.actions[]`, `.pages[]`) by editing the script.
- Set up a cron job to automate periodic updates:
  ```bash
  sudo crontab -e
  ```
  Example cron entry to run daily at 3 AM:
  ```
  0 3 * * * /path/to/update_github_ufw.sh

  