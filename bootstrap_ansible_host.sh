# shellcheck shell=bash
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
# Versions
###############################################################################

TERRAFORM_VERSION="1.13.0"

###############################################################################

set -euo pipefail

###############################################################################
# Error Handling
###############################################################################

trap 'echo; fail "Bootstrap failed at line $LINENO"' ERR
###############################################################################
# VARIABLES
###############################################################################

START_TIME=$(date +%s)

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

BOOTSTRAP_LOG="/var/log/platform-bootstrap.log"
###############################################################################
# COLOURS
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {

    echo "$(date '+%F %T') $1" >> "$BOOTSTRAP_LOG"

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

info "Validating sudo access..."

sudo -v || fail "Sudo privilege required."

ok "Sudo validated."

###############################################################################
# CREATE BOOTSTARTP LOGO
###############################################################################

sudo install -o root -g root -m 0644 /dev/null "$BOOTSTRAP_LOG"

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
# Internet Connectivity
###############################################################################

info "Checking Internet connectivity..."

curl -fsSL https://github.com >/dev/null \
    || fail "Unable to reach github.com"

ok "Internet connectivity verified."

###############################################################################
# UPDATE
###############################################################################

info "Updating operating system..."

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade

###############################################################################
# INSTALL BASE PACKAGES
###############################################################################

info "Installing packages..."

sudo apt-get install -y \
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
lsb-release \
bash-completion \
net-tools \
dnsutils \
telnet \
nmap \
rsync \
ncdu \
git-lfs \
htop \
iftop \
iotop \
tcpdump

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

mkdir -p "$KUBERNETES_HOME"

mkdir -p "$MONITORING_HOME"

mkdir -p "$SCRIPT_HOME"

mkdir -p "$DOC_HOME"

mkdir -p "$DOWNLOAD_HOME"

mkdir -p "$LOG_HOME"

mkdir -p "$ARTIFACT_HOME"

mkdir -p "$SSH_HOME"

mkdir -p "$CONFLUENT_HOME"/{
playbooks,
inventory,
downloads
}

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
export KUBERNETES_HOME=/app/platform/kubernetes
export MONITORING_HOME=/app/platform/monitoring

export PATH=\$HOME/.local/bin:\$PATH

EOF

fi

###############################################################################
# Install Terraform
###############################################################################

if command -v terraform >/dev/null

then

    ok "Terraform already installed."

else

    info "Installing Terraform ${TERRAFORM_VERSION}..."

    TMP_DIR=$(mktemp -d)

    cd "$TMP_DIR"

    wget -q --show-progress https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

    rm -f terraform
    
    unzip -oq terraform_${TERRAFORM_VERSION}_linux_amd64.zip

    sudo mv terraform /usr/local/bin/

    sudo chmod +x /usr/local/bin/terraform

    rm -rf "$TMP_DIR"

    terraform version >/dev/null \
    || fail "Terraform installation failed."

    terraform -install-autocomplete >/dev/null 2>&1 || true

    ok "Terraform installed."

fi

###############################################################################
# Install pipx
###############################################################################

if command -v pipx >/dev/null

then

    ok "pipx already installed."

else

    info "Installing pipx..."

    sudo apt-get install -y pipx

    pipx ensurepath

    hash -r
   
    export PATH="$HOME/.local/bin:$PATH"

fi

###############################################################################
# Install Ansible
###############################################################################

if command -v ansible >/dev/null

then

    ok "Ansible already installed."

else

    info "Installing Ansible..."

    pipx install ansible

    pipx install ansible-lint

    ok "Ansible installed."

    ansible --version >/dev/null \
    || fail "Ansible installation failed."

fi

ansible-galaxy collection list | grep -q "community.general" || \
    ansible-galaxy collection install community.general

ansible-galaxy collection list | grep -q "ansible.posix" || \
    ansible-galaxy collection install ansible.posix

###############################################################################
# Install Google Cloud CLI
###############################################################################

if command -v gcloud >/dev/null

then

    ok "Google Cloud CLI already installed."

else

    info "Installing Google Cloud CLI..."

    curl -fsSL \
https://packages.cloud.google.com/apt/doc/apt-key.gpg \
| sudo gpg --dearmor \
-o /usr/share/keyrings/cloud.google.gpg

    echo \
"deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
| sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null

    sudo apt-get update

    sudo apt-get install -y google-cloud-cli

    ok "Google Cloud CLI installed."

    gcloud version >/dev/null \
    || fail "Google Cloud CLI installation failed."

fi

###############################################################################
# Clone cp-ansible
###############################################################################

CP_ANSIBLE_HOME="${CONFLUENT_HOME}/cp-ansible-${CONFLUENT_VERSION}"

if [[ -d "$CP_ANSIBLE_HOME/.git" ]]

then

    info "Updating cp-ansible..."

    git -C "$CP_ANSIBLE_HOME" fetch --depth 1 origin

    git -C "$CP_ANSIBLE_HOME" reset --hard "origin/${CP_ANSIBLE_BRANCH}"

else

    info "Downloading cp-ansible..."

git clone \
    --depth 1 \
    -b "$CP_ANSIBLE_BRANCH" \
    https://github.com/confluentinc/cp-ansible.git \
    "$CP_ANSIBLE_HOME"

fi

ln -sfn \
"$CP_ANSIBLE_HOME" \
"${CONFLUENT_HOME}/current"

[[ -d "$CP_ANSIBLE_HOME" ]] || \
    fail "cp-ansible installation failed."
    
chmod -R u+rwX "$PLATFORM_HOME"

git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.autocrlf input

###############################################################################
# CLEANUP
###############################################################################
rm -rf /tmp/terraform*

sudo apt autoremove -y

sudo apt clean

###############################################################################
# SUMMARY
###############################################################################

echo
echo "=============================================================="
echo "Platform Engineering Bootstrap v1.0"
echo "=============================================================="

echo
echo "Platform Workspace"
echo "------------------"
echo "$PLATFORM_HOME"

echo
echo "Installed Versions"
echo "------------------"

terraform version | head -1
ansible --version | head -1
gcloud version | head -1
python3 --version
git --version
jq --version
yq --version

echo
echo "cp-ansible"
echo "-----------"
echo "${CONFLUENT_HOME}/current"

echo
echo "SSH Key"
echo "-------"
echo "~/.ssh/id_ed25519"

echo
echo "SSH Public Key"
echo "--------------"
cat ~/.ssh/id_ed25519.pub

echo
echo "Bootstrap Log"
echo "-------------"
echo "$BOOTSTRAP_LOG"

echo
echo "Next Steps"
echo "----------"
echo "1. source ~/.bashrc"
echo "2. gcloud auth login"
echo "3. gcloud config set project <PROJECT_ID>"
echo "4. cd $PLATFORM_HOME"

END_TIME=$(date +%s)

echo
echo "Execution Time"
echo "--------------"
echo "$((END_TIME-START_TIME)) seconds"

echo
echo "=============================================================="
ok "Bootstrap completed successfully."
