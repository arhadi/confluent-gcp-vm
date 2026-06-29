#!/usr/bin/env bash
###############################################################################
#
# bootstrap_ansible_host.sh
#
# Platform Engineering Lab Bootstrap
#
# Purpose
#   Bootstrap Ubuntu 24.04 LTS Minimal as the Platform Engineering host.
#
# Version
#   1.0
#
# Components
#   - Ubuntu validation
#   - System update
#   - Common packages
#   - Git
#   - Python3
#   - jq
#   - yq
#   - SSH key
#   - Platform directory structure
#
###############################################################################

set -euo pipefail

###############################################################################
# VARIABLES
###############################################################################

PLATFORM_HOME="/app/platform"

ANSIBLE_HOME="${PLATFORM_HOME}/ansible"
TERRAFORM_HOME="${PLATFORM_HOME}/terraform"
CONFLUENT_HOME="${PLATFORM_HOME}/confluent"
KUBERNETES_HOME="${PLATFORM_HOME}/kubernetes"
MONITORING_HOME="${PLATFORM_HOME}/monitoring"

SCRIPT_HOME="${PLATFORM_HOME}/scripts"
DOC_HOME="${PLATFORM_HOME}/docs"
DOWNLOAD_HOME="${PLATFORM_HOME}/downloads"
LOG_HOME="${PLATFORM_HOME}/logs"
ARTIFACT_HOME="${PLATFORM_HOME}/artifacts"

SSH_HOME="${PLATFORM_HOME}/ssh"

LOG_FILE="/tmp/bootstrap_ansible_host.log"

###############################################################################
# COLOURS
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {

    echo "$(date '+%F %T') $1" >> "$LOG_FILE"

}

info() {

    echo -e "${BLUE}[INFO]${NC} $1"

    log "[INFO] $1"

}

ok() {

    echo -e "${GREEN}[ OK ]${NC} $1"

    log "[ OK ] $1"

}

warn() {

    echo -e "${YELLOW}[WARN]${NC} $1"

    log "[WARN] $1"

}

fail() {

    echo -e "${RED}[FAIL]${NC} $1"

    log "[FAIL] $1"

    exit 1

}

###############################################################################
# CHECK USER
###############################################################################

if [[ $EUID -eq 0 ]]; then

    fail "Please run as ubuntu user, not root."

fi

###############################################################################
# CHECK SUDO
###############################################################################

sudo -v

###############################################################################
# CHECK OS
###############################################################################

source /etc/os-release

if [[ "$ID" != "ubuntu" ]]; then

    fail "Only Ubuntu is supported."

fi

if [[ "$VERSION_ID" != "24.04" ]]; then

    warn "Tested on Ubuntu 24.04."

fi

ok "Ubuntu ${VERSION_ID} detected."

###############################################################################
# UPDATE
###############################################################################

info "Updating operating system..."

sudo apt update

sudo apt -y upgrade

###############################################################################
# INSTALL BASE PACKAGES
###############################################################################

info "Installing packages..."

sudo apt install -y \
git \
curl \
wget \
zip \
unzip \
jq \
tree \
make \
vim \
nano \
python3 \
python3-pip \
python3-venv \
python3-dev \
openssh-client \
software-properties-common \
apt-transport-https \
ca-certificates \
gnupg \
lsb-release

ok "Base packages installed."

###############################################################################
# INSTALL YQ
###############################################################################

if command -v yq >/dev/null

then

    ok "yq already installed."

else

    info "Installing yq..."

    sudo wget -qO /usr/local/bin/yq \
https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64

    sudo chmod +x /usr/local/bin/yq

    ok "yq installed."

fi

###############################################################################
# CREATE PLATFORM HOME
###############################################################################

info "Creating platform workspace..."

sudo mkdir -p "$PLATFORM_HOME"

sudo chown -R "$USER:$USER" "$PLATFORM_HOME"

###############################################################################
# DIRECTORY STRUCTURE
###############################################################################

mkdir -p "$ANSIBLE_HOME"/{
inventory,
playbooks,
roles,
collections,
group_vars,
host_vars,
templates,
files
}

mkdir -p "$TERRAFORM_HOME"/{
gcp,
aws,
modules,
environments
}

mkdir -p "$CONFLUENT_HOME"

mkdir -p "$KUBERNETES_HOME"

mkdir -p "$MONITORING_HOME"

mkdir -p "$SCRIPT_HOME"

mkdir -p "$DOC_HOME"

mkdir -p "$DOWNLOAD_HOME"

mkdir -p "$LOG_HOME"

mkdir -p "$ARTIFACT_HOME"

mkdir -p "$SSH_HOME"

ok "Directory structure created."

###############################################################################
# SSH KEY
###############################################################################

mkdir -p ~/.ssh

if [[ ! -f ~/.ssh/id_ed25519 ]]

then

    info "Generating SSH key..."

    ssh-keygen \
-t ed25519 \
-a 100 \
-f ~/.ssh/id_ed25519 \
-C "platform@$(hostname)" \
-N ""

    ok "SSH key generated."

else

    warn "SSH key already exists."

fi

###############################################################################
# BASH PROFILE
###############################################################################

if ! grep -q PLATFORM_HOME ~/.bashrc

then

cat <<EOF >> ~/.bashrc

###############################################################################
# Platform Engineering
###############################################################################

export PLATFORM_HOME=/app/platform
export ANSIBLE_HOME=/app/platform/ansible
export TERRAFORM_HOME=/app/platform/terraform
export CONFLUENT_HOME=/app/platform/confluent

export PATH=\$HOME/.local/bin:\$PATH

EOF

fi

###############################################################################
# SUMMARY
###############################################################################

echo
echo "====================================================="
echo " Platform Engineering Bootstrap v1.0"
echo "====================================================="
echo

echo "Workspace"

echo "-------------------------------------"

echo "$PLATFORM_HOME"

echo

echo "Git"

git --version

echo

echo "Python"

python3 --version

echo

echo "jq"

jq --version

echo

echo "yq"

yq --version

echo

echo "SSH Public Key"

cat ~/.ssh/id_ed25519.pub

echo

echo "Next Steps"

echo "-------------------------------------"

echo "source ~/.bashrc"

echo "cd /app/platform"

echo

ok "Bootstrap completed successfully."
