#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Exit immediately if a command exits with a non-zero status -e
# Treat unset variables as an error and exit immediately -u
# Print each command to stderr before executing it (for debugging) -x
set -eux

# Sagemaker notebook currently uses amazon linux 2, which uses GLIBC 2.26, and code-server 4.16.1 is the last version that supports GLIBC 2.26
CODE_SERVER_VERSION="4.16.1"
CODE_SERVER_INSTALL_LOC="/home/ec2-user/SageMaker/.cs"
XDG_DATA_HOME="/home/ec2-user/SageMaker/.xdg/data"
XDG_CONFIG_HOME="/home/ec2-user/SageMaker/.xdg/config"
CREATE_NEW_CONDA_ENV=1
CONDA_ENV_LOCATION="/home/ec2-user/SageMaker/.cs/conda/envs/codeserver_py311"
CONDA_ENV_PYTHON_VERSION="3.11"

sudo -u ec2-user -i <<EOF

unset SUDO_UID

# Set the data and config home env variable for code-server
export XDG_DATA_HOME=$XDG_DATA_HOME
export XDG_CONFIG_HOME=$XDG_CONFIG_HOME
export PATH="$CODE_SERVER_INSTALL_LOC/bin/:$PATH"

# Install code-server standalone
mkdir -p ${CODE_SERVER_INSTALL_LOC}/lib ${CODE_SERVER_INSTALL_LOC}/bin
curl -fL https://github.com/coder/code-server/releases/download/v$CODE_SERVER_VERSION/code-server-$CODE_SERVER_VERSION-linux-amd64.tar.gz \
| tar -C ${CODE_SERVER_INSTALL_LOC}/lib -xz
mv ${CODE_SERVER_INSTALL_LOC}/lib/code-server-$CODE_SERVER_VERSION-linux-amd64 ${CODE_SERVER_INSTALL_LOC}/lib/code-server-$CODE_SERVER_VERSION
ln -s ${CODE_SERVER_INSTALL_LOC}/lib/code-server-$CODE_SERVER_VERSION/bin/code-server ${CODE_SERVER_INSTALL_LOC}/bin/code-server

# Create separate conda environment
if [ $CREATE_NEW_CONDA_ENV -eq 1 ]
then
    conda create --prefix $CONDA_ENV_LOCATION python=$CONDA_ENV_PYTHON_VERSION -y
fi

# Install extensions (code-server has a different marketplace than VSCode)
code-server --install-extension ms-python.python --force
code-server --install-extension eamodio.gitlens --force
code-server --install-extension njpwerner.autodocstring --force
code-server --install-extension ms-toolsai.jupyter --force
code-server --install-extension ms-vscode.cpptools-themes --force
code-server --install-extension foxundermoon.shell-format --force
code-server --install-extension redhat.vscode-yaml --force
code-server --install-extension DavidAnson.vscode-markdownlint --force

if command -v code-server &> /dev/null; then
    INSTALLED_VERSION=\$(code-server --version | head -n 1)
    echo "✅ code-server \$INSTALLED_VERSION successfully installed!"
else
    echo "❌ code-server installation verification failed!"
    exit 1
fi
EOF
