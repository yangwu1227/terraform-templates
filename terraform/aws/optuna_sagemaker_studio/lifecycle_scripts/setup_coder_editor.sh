#!/bin/bash
set -euo pipefail

# Ensure required commands are available (https://stackoverflow.com/a/677212/12923148)
for cmd in aws git conda curl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "$cmd could not be found"
    exit 1
  fi
done

# ------------------------------- Install tools ------------------------------ #

# Pipx exposes binaries at ~/.local/bin, add it to PATH so packages can be invoked globally once installed
echo "Configuring shell for pipx..."
LOCAL_BIN="$HOME/.local/bin"
# Add LOCAL_BIN to PATH in shell configuration files
for path in "$HOME/.bashrc" "$HOME/.zshrc"; do
  # Only add if not already present
  if [ -f "$path" ] && ! grep -q "export PATH=\"$LOCAL_BIN:\$PATH\"" "$path"; then
    echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >> "$path"
    echo "Updated $path"
  fi
done

# Install tools
echo "Installing tools..."
conda install --name base -y tree pipx

# Install dependency managers
echo "Installing dependency managers..."
pipx install uv poetry pdm

# -------------------------- Code editor extensions -------------------------- #

echo "Installing code-editor extensions..."
CODE_EDITOR_DIR="$HOME/sagemaker-code-editor-server-data/"

# Compatible with code-editor 1.90.1
extensions_urls=(
  "https://open-vsx.org/api/eamodio/gitlens/2025.2.1604/file/eamodio.gitlens-2025.2.1604.vsix"
  "https://open-vsx.org/api/ms-vscode/cpptools-themes/1.0.0/file/ms-vscode.cpptools-themes-1.0.0.vsix"
  "https://open-vsx.org/api/ms-azuretools/vscode-docker/1.29.2/file/ms-azuretools.vscode-docker-1.29.2.vsix"
  "https://open-vsx.org/api/njpwerner/autodocstring/0.6.1/file/njpwerner.autodocstring-0.6.1.vsix"
)

for url in "${extensions_urls[@]}"; do
  echo "Installing extension from $url..."
  curl -fsSL "$url" --output temp.vsix
  sagemaker-code-editor --install-extension temp.vsix --extensions-dir "$CODE_EDITOR_DIR/extensions"
  rm -f temp.vsix
done

# ------------------------- Settings & Configurations ------------------------ #

# Conda
echo "Configuring conda..."
conda config --set auto_activate_base false

# Git
echo "Configuring git..."
git config --global init.defaultBranch main
git config --global pull.rebase true

# Code-editor settings 
echo "Configuring code-editor..."
USER_CODE_EDITOR_DIR="$CODE_EDITOR_DIR/data/User"

# Settings
cat > "$USER_CODE_EDITOR_DIR/settings.json" <<EOF
{
    "jupyter.interactiveWindow.textEditor.executeSelection": true,
    "interactiveWindow.executeWithShiftEnter": true,
    "workbench.colorTheme": "Visual Studio 2017 Dark - C++",
    "python.terminal.activateEnvInCurrentTerminal": true,
    "files.insertFinalNewline": true
}
EOF

# Keyboard bindings
cat > "$USER_CODE_EDITOR_DIR/keybindings.json" <<EOF
[
    {
        "key": "cmd+enter",
        "command": "jupyter.execSelectionInteractive",
        "when": "editorTextFocus && isWorkspaceTrusted && jupyter.ownsSelection && !findInputFocussed && !notebookEditorFocused && !replaceInputFocussed && editorLangId == 'python'"
    },
    {
        "key": "shift+enter",
        "command": "-jupyter.execSelectionInteractive",
        "when": "editorTextFocus && isWorkspaceTrusted && jupyter.ownsSelection && !findInputFocussed && !notebookEditorFocused && !replaceInputFocussed && editorLangId == 'python'"
    }
]
EOF
