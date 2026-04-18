#!/bin/bash

# ==============================================
# Setup Script for Notes Express App
# ==============================================
# This script automates EVERYTHING:
#   1. Installs Docker & Docker Compose if missing
#   2. Installs Node.js & npm if missing
#   3. Copies .env.example to .env (if needed)
#   4. Installs npm dependencies
#   5. Builds and starts the app container
#   6. Runs the database setup (creates tables)
# ==============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   Notes Express App - Setup Script     ${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# ----------------------------
# Step 1: Install Docker
# ----------------------------
echo -e "${YELLOW}[1/6] Checking Docker...${NC}"

if command -v docker &> /dev/null; then
    echo -e "${GREEN}  ✔ Docker is already installed.${NC}"
else
    echo -e "${YELLOW}  ⏳ Installing Docker...${NC}"
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up the Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group (so no sudo needed next time)
    sudo usermod -aG docker $USER

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    echo -e "${GREEN}  ✔ Docker installed successfully.${NC}"
fi
echo ""

# ----------------------------
# Step 2: Check Docker Compose
# ----------------------------
echo -e "${YELLOW}[2/6] Checking Docker Compose...${NC}"

if docker compose version &> /dev/null; then
    echo -e "${GREEN}  ✔ Docker Compose (plugin) is available.${NC}"
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}  ✔ Docker Compose (standalone) is available.${NC}"
    COMPOSE_CMD="docker-compose"
else
    echo -e "${YELLOW}  ⏳ Installing Docker Compose standalone...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    COMPOSE_CMD="docker-compose"
    echo -e "${GREEN}  ✔ Docker Compose installed.${NC}"
fi
echo ""

# ----------------------------
# Step 3: Setup .env file
# ----------------------------
echo -e "${YELLOW}[3/6] Setting up environment file...${NC}"

if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}  ✔ Created .env from .env.example.${NC}"
        echo -e "${YELLOW}  ⚠ Edit .env with your database credentials (DB_HOST, DB_USER, DB_PASS, DB_DATABASE).${NC}"
    else
        echo -e "${RED}Error: .env.example not found.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}  ✔ .env file already exists.${NC}"
fi
echo ""

# ----------------------------
# Step 4: Install npm dependencies
# ----------------------------
echo -e "${YELLOW}[4/6] Installing npm dependencies...${NC}"

if command -v node &> /dev/null; then
    echo -e "${GREEN}  ✔ Node.js $(node -v) found.${NC}"
else
    echo -e "${YELLOW}  ⏳ Installing Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo -e "${GREEN}  ✔ Node.js installed.${NC}"
fi

npm install
echo -e "${GREEN}  ✔ npm dependencies installed.${NC}"
echo ""

# ----------------------------
# Step 5: Build and start app
# ----------------------------
echo -e "${YELLOW}[5/6] Building and starting the app container...${NC}"
sudo $COMPOSE_CMD up -d --build
echo -e "${GREEN}  ✔ App container started.${NC}"
echo ""

# ----------------------------
# Step 6: Run DB setup
# ----------------------------
echo -e "${YELLOW}[6/6] Running database setup...${NC}"
sleep 5  # Give the app a moment to start
sudo $COMPOSE_CMD exec -T app npm run setup
echo -e "${GREEN}  ✔ Database tables created.${NC}"
echo ""

# ----------------------------
# Done!
# ----------------------------
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  ✔ Setup complete!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "  App running at:  ${GREEN}http://localhost:3000${NC}"
echo ""
echo -e "  Useful commands:"
echo -e "    ${CYAN}make logs${NC}      - View logs"
echo -e "    ${CYAN}make down${NC}      - Stop container"
echo -e "    ${CYAN}make restart${NC}   - Restart container"
echo -e "    ${CYAN}make shell${NC}     - Shell into app container"
echo ""
