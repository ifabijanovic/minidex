#!/bin/bash

# --- Configuration ---
TARGET_PLATFORM="linux/arm64"
WEB_TAG="minidex-web:latest"
SERVER_TAG="minidex-server:latest"
IMAGE_TAR="minidex_images.tar"
ENV_FILE="deploy/production.env"
DEPLOY_DIR="deploy"
REMOTE_DIR="minidex"
SSH_KEY_FILE="${HOME}/.ssh/id_ed25519"

# Dockerfile and Context Paths
WEB_DOCKERFILE="web/Dockerfile"
WEB_CONTEXT="./web"
SERVER_DOCKERFILE="Dockerfile"
SERVER_CONTEXT="."

# --- 1. Parameter and File Validation ---
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "🚨 Error: Missing required parameters."
    echo "Usage: $0 <REMOTE_USERNAME> <REMOTE_ADDRESS>"
    echo "Example: $0 user 192.168.1.100"
    exit 1
fi

REMOTE_USERNAME="$1"
REMOTE_ADDRESS="$2"
REMOTE_PATH="/home/${REMOTE_USERNAME}/${REMOTE_DIR}"

# Check for required local files
if [ ! -f "$SERVER_DOCKERFILE" ]; then echo "❌ Error: Server Dockerfile ($SERVER_DOCKERFILE) not found. Aborting."; exit 1; fi
if [ ! -f "$WEB_DOCKERFILE" ]; then echo "❌ Error: Web Dockerfile ($WEB_DOCKERFILE) not found. Aborting."; exit 1; fi
if [ ! -f "${DEPLOY_DIR}/docker-compose.yml" ]; then echo "❌ Error: ${DEPLOY_DIR}/docker-compose.yml not found. Aborting."; exit 1; fi
if [ ! -f "${DEPLOY_DIR}/Caddyfile" ]; then echo "❌ Error: ${DEPLOY_DIR}/Caddyfile not found. Aborting."; exit 1; fi

echo "--- Starting Cross-Architecture Deployment ---"
echo "Target: ${REMOTE_USERNAME}@${REMOTE_ADDRESS}:${REMOTE_PATH}"

# --- 2. SSH Agent Setup ---

echo "🔑 Starting SSH Agent..."
eval "$(ssh-agent -s)" > /dev/null
# SSH_AGENT_PID is set by the eval above

cleanup() {
    if [ -n "$SSH_AGENT_PID" ]; then
        echo -e "\n🧹 Killing SSH Agent ($SSH_AGENT_PID)..."
        kill "$SSH_AGENT_PID" 2>/dev/null || true
    fi
    rm -f "$IMAGE_TAR"
}
trap cleanup EXIT

echo "🔑 Please enter your SSH key passphrase when prompted (Only once):"
if ! ssh-add "$SSH_KEY_FILE"; then
    echo "❌ Failed to add key. Passphrase was incorrect or key file not found."
    exit 1
fi

# --- 3. Build Images for Target Platform ---

# Build the Web Image (using web/Dockerfile and ./web context)
echo "⚙️ Building $WEB_TAG for $TARGET_PLATFORM (Context: $WEB_CONTEXT)..."
docker buildx build --platform "$TARGET_PLATFORM" -f "$WEB_DOCKERFILE" -t "$WEB_TAG" --load "$WEB_CONTEXT"
if [ $? -ne 0 ]; then echo "❌ Web image build failed. Aborting."; exit 1; fi

# Build the Server Image (using Dockerfile and root context)
echo "⚙️ Building $SERVER_TAG for $TARGET_PLATFORM (Context: $SERVER_CONTEXT)..."
docker buildx build --platform "$TARGET_PLATFORM" -f "$SERVER_DOCKERFILE" -t "$SERVER_TAG" --load "$SERVER_CONTEXT"
if [ $? -ne 0 ]; then echo "❌ Server image build failed. Aborting."; exit 1; fi


# --- 4. Save Images and Prepare Files ---
echo "📦 Saving images to $IMAGE_TAR..."
docker save "$WEB_TAG" "$SERVER_TAG" -o "$IMAGE_TAR"
if [ $? -ne 0 ]; then echo "❌ Docker save failed. Aborting."; exit 1; fi

if [ ! -f "$ENV_FILE" ]; then echo "⚠️ Warning: $ENV_FILE not found. Proceeding without .env file."; fi

# --- 5. Transfer Files via SCP ---
echo "🚀 Transferring files to remote server..."

# Create the remote directory if it doesn't exist
ssh "$REMOTE_USERNAME@$REMOTE_ADDRESS" "mkdir -p ${REMOTE_PATH}"

# Copy files individually with correct remote names
echo "📤 Copying Docker images..."
scp "$IMAGE_TAR" "$REMOTE_USERNAME@$REMOTE_ADDRESS:${REMOTE_PATH}/"
if [ $? -ne 0 ]; then echo "❌ Failed to copy Docker images. Aborting."; exit 1; fi

echo "📤 Copying docker-compose.yml..."
scp "${DEPLOY_DIR}/docker-compose.yml" "$REMOTE_USERNAME@$REMOTE_ADDRESS:${REMOTE_PATH}/docker-compose.yml"
if [ $? -ne 0 ]; then echo "❌ Failed to copy docker-compose.yml. Aborting."; exit 1; fi

echo "📤 Copying Caddyfile..."
scp "${DEPLOY_DIR}/Caddyfile" "$REMOTE_USERNAME@$REMOTE_ADDRESS:${REMOTE_PATH}/Caddyfile"
if [ $? -ne 0 ]; then echo "❌ Failed to copy Caddyfile. Aborting."; exit 1; fi

# Copy .env file if it exists
if [ -f "$ENV_FILE" ]; then
    echo "📤 Copying production.env..."
    scp "$ENV_FILE" "$REMOTE_USERNAME@$REMOTE_ADDRESS:${REMOTE_PATH}/.env"
    if [ $? -ne 0 ]; then echo "❌ Failed to copy production.env. Aborting."; exit 1; fi
fi

# Load the images on the remote server
echo "🛠️ Loading images on remote server..."
ssh "$REMOTE_USERNAME@$REMOTE_ADDRESS" "cd ${REMOTE_PATH} && docker load -i ${IMAGE_TAR}"
if [ $? -ne 0 ]; then echo "❌ Docker load failed on remote server. Aborting."; exit 1; fi

# --- 6. Instructions for Final Steps ---
echo -e "\n✅ Deployment preparation complete."
echo "--------------------------------------------------------"
echo "NEXT STEPS (Execute these on your remote server via SSH):"
echo "1. Run database migrations:"
echo "   cd ${REMOTE_PATH} && docker compose run --rm migrate"
echo "2. Start the application in detached mode:"
echo "   docker compose up -d"
echo "--------------------------------------------------------"
