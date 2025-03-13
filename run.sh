#!/bin/bash

USER="erviker"  # Change this if needed
NEW_HOST="$USER@new-host"  # Change to the new host's IP or hostname
BACKUP_DIR="/tmp/docker_migration"
EXCLUDE_VOLUMES=("portainer_data")
REMOTE_COMPOSE_DIR="/opt/dockage"

# Check for SSH key and set up if missing
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo "🔑 No SSH key found. Generating one..."
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""
fi

echo "🔐 Copying SSH key to $NEW_HOST..."
ssh-copy-id "$NEW_HOST"

echo "🔍 Checking dependencies on new host..."
ssh "$NEW_HOST" << EOF
    if ! groups $USER | grep -q "docker"; then
        echo "❌ User $USER is not in the docker group. Adding user..."
        sudo usermod -aG docker $USER
        echo "✅ User $USER added to docker group. Please log out and back in."
        exit 1
    fi

    if ! command -v docker &>/dev/null; then
        echo "❌ Docker not found. Installing..."
        sudo dnf install -y docker docker-compose
        sudo systemctl enable --now docker
    fi

    if ! systemctl is-active --quiet docker; then
        echo "❌ Docker is not running. Starting..."
        sudo systemctl start docker
    fi

    if [ ! -d "$REMOTE_COMPOSE_DIR" ]; then
        echo "✅ Creating $REMOTE_COMPOSE_DIR..."
        sudo mkdir -p "$REMOTE_COMPOSE_DIR"
        sudo chown $USER:docker "$REMOTE_COMPOSE_DIR"
    fi
EOF

echo "✅ New host is ready for migration."

mkdir -p "$BACKUP_DIR"

echo "⏳ Stopping all running containers..."
docker ps -q | xargs docker stop

echo "🔍 Detecting Docker Compose stacks..."
docker ps --format '{{.Label "com.docker.compose.project"}}' | sort -u | grep -v '^$' > "$BACKUP_DIR/docker_compose_stacks.txt"

echo "📦 Copying Docker Compose files..."
while read -r stack; do
    STACK_PATH=$(find / -name "$stack" -type d 2>/dev/null | head -n 1)
    if [[ -n "$STACK_PATH" ]]; then
        DEST_PATH="$REMOTE_COMPOSE_DIR/$stack"
        ssh "$NEW_HOST" "mkdir -p $DEST_PATH"
        rsync -avz "$STACK_PATH/docker-compose.yml" "$NEW_HOST:$DEST_PATH/compose.yaml"
        rsync -avz "$STACK_PATH/.env" "$NEW_HOST:$DEST_PATH/" 2>/dev/null
    fi
done < "$BACKUP_DIR/docker_compose_stacks.txt"

echo "📦 Extracting and migrating Portainer stacks..."
PORTAINER_DATA_DIR="/var/lib/docker/volumes/portainer_data/_data"
if [ -d "$PORTAINER_DATA_DIR" ]; then
    STACKS_JSON="$BACKUP_DIR/portainer_stacks.json"
    docker stop portainer
    cp "$PORTAINER_DATA_DIR/stack/"*.json "$STACKS_JSON"

    for stack_file in "$STACKS_JSON"/*.json; do
        STACK_NAME=$(jq -r '.Name' "$stack_file")
        STACK_CONTENT=$(jq -r '.FileContent' "$stack_file")
        STACK_ENV=$(jq -r '.Env | map("\(.name)=\(.value)") | join("\n")' "$stack_file")

        if [[ -n "$STACK_NAME" ]]; then
            DEST_PATH="$REMOTE_COMPOSE_DIR/$STACK_NAME"
            ssh "$NEW_HOST" "mkdir -p $DEST_PATH"
            echo "$STACK_CONTE
