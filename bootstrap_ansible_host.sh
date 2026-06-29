#!/usr/bin/env bash
###############################################################################
# bootstrap_ansible_host.sh
#
# Platform Engineering Lab Bootstrap
#
# Purpose:
#   Bootstrap Ubuntu 24.04 LTS Minimal as an Automation Host
#
# Components Installed
#   - Git
#   - Terraform
#   - Ansible
#   - Python3
#   - pip
#   - GCP CLI
#   - jq
#   - yq
#   - unzip
#   - curl
#   - wget
#   - tree
#   - make
#   - ssh key
#   - cp-ansible
#
# Author : Arif Lab
# Version: 1.0
###############################################################################

set -euo pipefail

###############################################################################
# Variables
###############################################################################

LAB_HOME="$HOME/lab"
CP_ANSIBLE_DIR="$LAB_HOME/cp-ansible"
SSH_DIR="$HOME/.ssh"

TERRAFORM_VERSION="1.13.0"

###############################################################################
# Colors
###############################################################################

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

ok() {
    echo -e "${GREEN}[ OK ]${RESET} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

err() {
    echo -e "${RED}[FAIL]${RESET} $1"
}

###############################################################################
# Root Check
###############################################################################

if [[ $EUID -eq 0 ]]; then
    err "Do NOT run as root."
    exit 1
fi

###############################################################################
# Update OS
###############################################################################

info "Updating Ubuntu..."

sudo apt update
sudo apt -y upgrade

###############################################################################
# Install Base Packages
###############################################################################

info "Installing packages..."

sudo apt install -y \
git \
curl \
wget \
jq \
unzip \
zip \
tree \
make \
python3 \
python3-pip \
python3-venv \
python3-dev \
openssh-client \
software-properties-common \
ca-certificates \
apt-transport-https \
gnupg \
lsb-release

ok "Packages installed."

###############################################################################
# Install yq
###############################################################################

if ! command -v yq >/dev/null
then
    info "Installing yq..."

    sudo wget -qO /usr/local/bin/yq \
https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64

    sudo chmod +x /usr/local/bin/yq

    ok "yq installed."
fi

###############################################################################
# Install Terraform
###############################################################################

if ! command -v terraform >/dev/null
then

    info "Installing Terraform ${TERRAFORM_VERSION}..."

    wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip

    sudo mv terraform /usr/local/bin/

    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

    ok "Terraform installed."

fi

###############################################################################
# Install Ansible
###############################################################################

if ! command -v ansible >/dev/null
then

    info "Installing Ansible..."

    python3 -m pip install --user --upgrade pip

    python3 -m pip install --user \
ansible \
ansible-lint \
jmespath \
netaddr

    ok "Ansible installed."

fi

###############################################################################
# Install Google Cloud CLI
###############################################################################

if ! command -v gcloud >/dev/null
then

    info "Installing Google Cloud CLI..."

    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | \
sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null

    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

    sudo apt update

    sudo apt install -y google-cloud-cli

    ok "Google Cloud CLI installed."

fi

###############################################################################
# SSH Key
###############################################################################

mkdir -p "$SSH_DIR"

if [[ ! -f "$SSH_DIR/id_ed25519" ]]
then

    info "Generating SSH key..."

    ssh-keygen \
-t ed25519 \
-a 100 \
-C "platform-lab" \
-f "$SSH_DIR/id_ed25519" \
-N ""

    ok "SSH Key generated."

else

    warn "SSH key already exists."

fi

###############################################################################
# Directory Structure
###############################################################################

info "Creating Lab directory..."

mkdir -p "$LAB_HOME"

mkdir -p "$LAB_HOME"/{
terraform,
ansible,
inventory,
scripts,
docs,
downloads,
artifacts,
logs,
ssh
}

mkdir -p "$LAB_HOME/terraform/modules"

mkdir -p "$LAB_HOME/ansible"/{
inventory,
group_vars,
host_vars,
roles,
playbooks,
collections,
files,
templates
}

ok "Directory structure created."

###############################################################################
# Clone cp-ansible
###############################################################################

if [[ ! -d "$CP_ANSIBLE_DIR" ]]
then

    info "Downloading cp-ansible..."

    git clone \
https://github.com/confluentinc/cp-ansible.git \
"$CP_ANSIBLE_DIR"

    ok "cp-ansible downloaded."

else

    warn "cp-ansible already exists."

fi

###############################################################################
# Bash Profile
###############################################################################

if ! grep -q "LAB_HOME" ~/.bashrc
then

cat <<EOF >> ~/.bashrc

#################################################
# Platform Engineering Lab
#################################################

export LAB_HOME=$LAB_HOME
export PATH=\$HOME/.local/bin:\$PATH

EOF

fi

###############################################################################
# Git Configuration
###############################################################################

warn "Configure Git if required."

echo

echo "git config --global user.name  \"Your Name\""
echo "git config --global user.email \"your@email.com\""

###############################################################################
# Summary
###############################################################################

echo
echo "==========================================="
echo "Bootstrap Completed"
echo "==========================================="
echo

echo "Lab Home:"
echo "$LAB_HOME"

echo

echo "Terraform:"
terraform version || true

echo

echo "Git:"
git --version

echo

echo "Python:"
python3 --version

echo

echo "Ansible:"
$HOME/.local/bin/ansible --version | head -1 || true

echo

echo "GCloud:"
gcloud version | head -1 || true

echo

echo "Public SSH Key:"
cat ~/.ssh/id_ed25519.pub

echo

echo "Next Steps"

echo "-------------------------------------------"

echo "1. source ~/.bashrc"

echo "2. gcloud auth login"

echo "3. gcloud config set project <PROJECT_ID>"

echo "4. cd ~/lab"

echo "5. Start Terraform"

echo

ok "Bootstrap completed successfully."
