# utils
Configs 'n things

## Contents

### Configurations
- **Oh My Posh themes** - Terminal prompt themes in [config/omp/](config/omp/)

### OpenCode Skills
- **server-update** - Automated server package updates via SSH with interactive conflict resolution

### Scripts
- **server-updater.sh** - Shell script for updating packages on remote servers

## Server Update Skill

An OpenCode skill for keeping multiple servers up to date with package updates.

### Setup

1. **Install dependencies** (macOS):
   ```bash
   brew install jq
   ```

2. **Create your server configuration**:
   ```bash
   cp config/servers/servers.example.json config/servers/servers.json
   ```

3. **Edit `config/servers/servers.json`** with your actual server details:
   - Server hostnames/IPs
   - SSH username
   - Update commands for your OS

4. **Make the script executable**:
   ```bash
   chmod +x scripts/server-updater.sh
   ```

### Usage with OpenCode

Start OpenCode in this directory and invoke the skill:

```
@skill server-update

Please update all my servers
```

OpenCode will:
- Read your server configuration
- SSH into each server sequentially
- Run the configured update commands
- Handle any interactive prompts that come up
- Report the results

### Manual Usage

You can also run the script directly:

```bash
# Update all servers
./scripts/server-updater.sh config/servers/servers.json

# Update a specific server
./scripts/server-updater.sh config/servers/servers.json web-server-01
```

### Security Notes

⚠️ **IMPORTANT**: Never commit `config/servers/servers.json` to git! It contains sensitive server information and credentials.

- The actual config file is in `.gitignore`
- Only `servers.example.json` is tracked in git
- Use SSH keys (not passwords) for authentication
- Store SSH keys securely with appropriate permissions (`chmod 600`)

### Server Config Structure

```json
{
  "servers": [
    {
      "name": "server-identifier",
      "host": "hostname-or-ip",
      "user": "ssh-username",
      "os": "ubuntu",
      "updateCommands": [
        "sudo apt-get update",
        "sudo apt-get upgrade -y"
      ]
    }
  ]
}
```

SSH authentication relies on your existing SSH configuration (keys in `~/.ssh/` and settings in `~/.ssh/config`).
