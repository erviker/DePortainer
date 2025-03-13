# 🚀 Docker Migration Script

This script automates the process of migrating Docker containers, volumes, and Portainer stacks from one host to another host running dockage, supporting **both Red Hat-based (Rocky, RHEL, CentOS) and Debian-based (Ubuntu, Debian) distributions**.

## 📌 Features
✅ Automatically sets up **SSH key-based authentication** if needed  
✅ Ensures the new host has **Docker & Docker Compose installed and running**  
✅ Supports **both Red Hat and Debian-based operating systems**  
✅ Adds the specified user to the **Docker group** if missing  
✅ Migrates all **Docker Compose stacks** (renaming `docker-compose.yml` → `compose.yaml`)  
✅ Extracts and transfers **Portainer stacks** (but **does not** move Portainer itself)  
✅ Transfers **Docker volumes and bind mounts**  
✅ Starts all migrated containers on the new host  

---

## 🔧 Prerequisites
Ensure the following:
- You have **SSH access** to both the old and new host
- The new host is running **Rocky Linux, RHEL, CentOS, Ubuntu, or Debian**
- The script is executed with a user that has **sudo privileges**

---

## 📥 Installation
1. Clone this repository:
   ```sh
   git clone https://github.com/erviker/DePortainer.git
   cd DePortainer
   ```
2. Make the script executable:
   ```sh
   chmod +x run.sh
   ```

---

## 🚀 Usage
Run the script on the **old host**:
```sh
./run.sh
```

### **Customization**
The script defines the following variables:
```sh
USER="erviker"  # Change this to the target user on the new host
NEW_HOST="$USER@new-host"  # Change to the new host's IP or hostname
REMOTE_COMPOSE_DIR="/opt/dockage"  # Directory to store Compose files on new host
EXCLUDE_VOLUMES=("portainer_data")  # Volumes to exclude from migration
```
Modify them as needed before running the script.

---

## 📜 How It Works
1. **Checks & Sets Up SSH Access**
   - Detects if an SSH key exists
   - Generates a new key if missing
   - Copies the key to the new host

2. **Prepares the New Host**
   - Ensures Docker & Docker Compose are installed and running
   - Detects whether the OS is Red Hat-based or Debian-based and installs the correct packages
   - Adds the user to the Docker group
   - Creates the necessary `/opt/dockage/` directory

3. **Migrates Docker Compose Stacks**
   - Detects Compose stacks
   - Copies `docker-compose.yml` as `compose.yaml`
   - Transfers `.env` files if present

4. **Migrates Portainer Stacks** (if applicable)
   - Extracts stack data from Portainer
   - Recreates stacks on the new host

5. **Transfers Volumes & Bind Mounts**
   - Archives volumes and moves them to the new host
   - Recreates volumes and restores data
   - Syncs bind-mounted directories

6. **Restores & Restarts Containers**
   - Deploys all transferred Compose stacks on the new host

---

## 🛠 Troubleshooting
- If SSH authentication fails, manually add your SSH key:
  ```sh
  ssh-copy-id $USER@new-host
  ```
- If Docker is not found on the new host, install it manually:
  ```sh
  # For Red Hat-based systems
  sudo dnf install -y docker docker-compose-plugin
  
  # For Debian-based systems
  sudo apt update && sudo apt install -y docker.io docker-compose
  
  sudo systemctl enable --now docker
  ```
- Ensure the user is in the Docker group:
  ```sh
  sudo usermod -aG docker $USER
  ```

---

## 📜 License
This script is open-source under the MIT License.

---

## 👨‍💻 Contributing
Feel free to submit issues or pull requests to improve the script!

---

## 📞 Support
For questions or suggestions, open an issue on this repository.
