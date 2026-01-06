#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Configuration and State Tracking
# ============================================================================

# Track installation state for cleanup on interrupt
BINARY_RENAMED=false
WRAPPER_CREATED=false
PYTHON_SCRIPT_COPIED=false
PROFILE_MODIFIED=()
VENV_HOOKS_ADDED=()

# Constants
WRAPPER_DIR="$HOME/.specstory_wrapper"
WRAPPER_BIN="$HOME/bin/specstory"
CLAUDE_WRAPPER_BIN="$HOME/bin/claude"
PYTHON_WRAPPER="$WRAPPER_DIR/specstory_wrapper.py"
PATH_EXPORT='export PATH="$HOME/bin:$PATH"'

# ============================================================================
# Helper Functions
# ============================================================================

# Safely remove a file or directory
safe_remove() {
  local target="$1"
  [[ -e "$target" ]] && rm -rf "$target" 2>/dev/null || true
}

# Restore profile file by removing PATH export line
restore_profile() {
  local profile="$1"
  if [[ -f "$profile" ]] && [[ -s "$profile" ]]; then
    # Use temp file to safely remove line; preserve file if grep finds nothing
    if grep -v "^${PATH_EXPORT}$" "$profile" > "${profile}.tmp" 2>/dev/null; then
      mv "${profile}.tmp" "$profile" 2>/dev/null || true
    fi
    rm -f "${profile}.tmp" 2>/dev/null || true
  fi
}

# Remove venv hook sections from a script file
remove_venv_hooks() {
  local hook_file="$1"
  if [[ ! -f "$hook_file" ]]; then
    return
  fi

  # Remove hook sections
  # macOS sed requires backup extension, Linux doesn't - use empty string for macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' \
      -e '/# SPECSTORY HOOK START/,/# SPECSTORY HOOK END/d' \
      -e '/# SPECSTORY DEACTIVATE HOOK/,/unset -f claude/d' \
      -e '/# SPECSTORY DEACTIVATE HOOK/,/unalias claude/d' \
      -e '/^[[:space:]]*# SPECSTORY DEACTIVATE HOOK$/d' \
      -e '/^[[:space:]]*unset -f claude 2>\/dev\/null || true$/d' \
      -e '/^[[:space:]]*unalias claude 2>\/dev\/null || true$/d' \
      "$hook_file" 2>/dev/null || true
  else
    sed -i \
      -e '/# SPECSTORY HOOK START/,/# SPECSTORY HOOK END/d' \
      -e '/# SPECSTORY DEACTIVATE HOOK/,/unset -f claude/d' \
      -e '/# SPECSTORY DEACTIVATE HOOK/,/unalias claude/d' \
      -e '/^[[:space:]]*# SPECSTORY DEACTIVATE HOOK$/d' \
      -e '/^[[:space:]]*unset -f claude 2>\/dev\/null || true$/d' \
      -e '/^[[:space:]]*unalias claude 2>\/dev\/null || true$/d' \
      "$hook_file" 2>/dev/null || true
  fi
}

# ============================================================================
# Cleanup Function
# ============================================================================

cleanup_on_interrupt() {
  echo
  echo "⚠ Installation interrupted. Cleaning up..."
  
  # Restore binary if it was renamed
  if [[ "$BINARY_RENAMED" == "true" ]] && [[ -f "$REAL_WRAPPED" ]] && [[ ! -f "$REAL_BIN" ]]; then
    echo "  Restoring original binary..."
    mv "$REAL_WRAPPED" "$REAL_BIN" 2>/dev/null || true
  fi
  
  # Remove wrapper if it was created
  if [[ "$WRAPPER_CREATED" == "true" ]]; then
    echo "  Removing wrapper binaries..."
    safe_remove "$WRAPPER_BIN"
    safe_remove "$CLAUDE_WRAPPER_BIN"
  fi
  
  # Remove Python script if it was copied
  if [[ "$PYTHON_SCRIPT_COPIED" == "true" ]]; then
    echo "  Removing Python wrapper script..."
    safe_remove "$PYTHON_WRAPPER"
    rmdir "$WRAPPER_DIR" 2>/dev/null || true
  fi
  
  # Restore profile files
  for profile in "${PROFILE_MODIFIED[@]}"; do
    echo "  Restoring $profile..."
    restore_profile "$profile"
  done
  
  # Remove venv hooks
  for hook_file in "${VENV_HOOKS_ADDED[@]}"; do
    echo "  Removing venv hook: $hook_file..."
    if [[ "$hook_file" == *.sh ]]; then
      safe_remove "$hook_file"
    elif [[ "$hook_file" == */activate ]] || [[ "$hook_file" == */deactivate ]]; then
      remove_venv_hooks "$hook_file"
    fi
  done
  
  echo "  Cleanup complete. No changes were made."
  exit 130
}

# Set up trap for Ctrl+C (SIGINT)
trap cleanup_on_interrupt INT

# ============================================================================
# Main Installation
# ============================================================================

echo "Installing Specstory wrapper..."

# --- Step 0: Pre-flight checks ---
# Get script directory (works in both bash and zsh)
# Use BASH_SOURCE if available (bash), otherwise fall back to $0
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
WRAPPER_PY_SOURCE="${SCRIPT_DIR}/specstory_wrapper.py"

if [[ ! -f "$WRAPPER_PY_SOURCE" ]]; then
  echo "Error: specstory_wrapper.py not found at $WRAPPER_PY_SOURCE"
  echo "Please run this installer from the directory containing specstory_wrapper.py"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required but not found in PATH."
  exit 1
fi

# --- Step 1: Locate real specstory binary ---
REAL_BIN="$(command -v specstory || true)"
if [[ -z "$REAL_BIN" ]]; then
  echo "Error: Specstory not found in PATH."
  echo "Install it first: brew install specstoryai/tap/specstory"
  exit 1
fi

REAL_DIR="$(dirname "$REAL_BIN")"
REAL_WRAPPED="$REAL_DIR/specstory-real"

# --- Step 2: Rename real binary (if not already renamed) ---
# Try to rename, but if we lack permission (common on Linux/system installs),
# fall back to leaving the original in place and instruct the wrapper to call it.
if [[ ! -f "$REAL_WRAPPED" ]]; then
  echo "➡ Attempting to rename $REAL_BIN → $REAL_WRAPPED"
  if mv "$REAL_BIN" "$REAL_WRAPPED" 2>/dev/null; then
    BINARY_RENAMED=true
    SPECSTORY_REAL_PATH="$REAL_WRAPPED"
  else
    echo "⚠ Could not rename $REAL_BIN (insufficient permissions or other error)."
    echo "  Will keep the original binary in place and configure the wrapper to call it directly."
    BINARY_RENAMED=false
    SPECSTORY_REAL_PATH="$REAL_BIN"
  fi
else
  echo "✔ Real binary already renamed."
  SPECSTORY_REAL_PATH="$REAL_WRAPPED"
fi

# --- Step 3: Install wrapper launchers ---
mkdir -p "$HOME/bin"
echo "➡ Installing specstory wrapper launcher → $WRAPPER_BIN"
cat > "$WRAPPER_BIN" <<EOF
#!/usr/bin/env bash
# Provide the resolver script the path to the original specstory binary.
export SPECSTORY_ORIGINAL="$SPECSTORY_REAL_PATH"
exec python3 "$PYTHON_WRAPPER" "\$@"
EOF

echo "➡ Installing claude wrapper launcher → $CLAUDE_WRAPPER_BIN"

cat > "$CLAUDE_WRAPPER_BIN" <<'EOF'
#!/usr/bin/env bash
FILTERED_PATH="$(echo "$PATH" | tr ':' '\n' | grep -v "^${HOME}/bin$" | tr '\n' ':' | sed 's/:$//')"
export PATH="$FILTERED_PATH"
exec "$HOME/bin/specstory" run claude --no-cloud-sync "$@"
EOF

chmod +x "$WRAPPER_BIN" "$CLAUDE_WRAPPER_BIN"
WRAPPER_CREATED=true

# --- Step 4: Install Python wrapper script ---
echo "➡ Copying specstory_wrapper.py → $WRAPPER_DIR/"
mkdir -p "$WRAPPER_DIR"
cp "$WRAPPER_PY_SOURCE" "$PYTHON_WRAPPER"
PYTHON_SCRIPT_COPIED=true

# --- Step 5: Add ~/bin to PATH in shell configs ---
# We prepend it to ensure our wrappers take priority over system binaries.
if [[ ":$PATH:" != *":$HOME/bin:"* ]] || [[ "$PATH" != "$HOME/bin:"* ]]; then
  echo "➡ Ensuring ~/bin is at the start of PATH in shell configs"
  
  for profile in "$HOME/.zshrc" "$HOME/.bashrc"; do
    [[ ! -f "$profile" ]] && touch "$profile"
    
    # Remove existing ~/bin exports to avoid duplicates and ensure priority
    # macOS sed requires backup extension, Linux doesn't - use empty string for macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' '/export PATH="\$HOME\/bin:\$PATH"/d' "$profile"
    else
      sed -i '/export PATH="\$HOME\/bin:\$PATH"/d' "$profile"
    fi
    
    # Prepend it
    echo "$PATH_EXPORT" >> "$profile"
    PROFILE_MODIFIED+=("$profile")
  done
  echo "✔ ~/bin configured at the end of shell profiles (will be prepended on next shell start)"
fi

# ============================================================================
# Virtual Environment Setup
# ============================================================================

# Hook content templates (functions to generate hook content)
get_activation_hook() {
  cat <<'EOF'
export PATH="$HOME/bin:$PATH"
# Use function instead of alias for better compatibility
# Filters $HOME/bin from PATH before calling specstory to avoid infinite recursion
claude() {
  local filtered_path
  filtered_path="$(echo "$PATH" | tr ':' '\n' | grep -v "^${HOME}/bin$" | tr '\n' ':' | sed 's/:$//')"
  PATH="$filtered_path" specstory run claude --no-cloud-sync "$@"
}
EOF
}

get_deactivation_hook() {
  cat <<'EOF'
# Remove claude function if it exists
unset -f claude 2>/dev/null || true
EOF
}

# Create conda hooks
setup_conda_hooks() {
  local env_name="$1"
  local env_path
  
  if ! command -v conda >/dev/null 2>&1; then
    echo "Error: conda not found in PATH."
    exit 1
  fi

  # Validate environment name
  if [[ -z "$env_name" ]] || [[ "$env_name" =~ [^a-zA-Z0-9_-] ]]; then
    echo "Error: Invalid environment name. Use only alphanumeric characters, underscores, and hyphens."
    exit 1
  fi

  # Get environment path (anchor regex to prevent partial matches)
  env_path="$(conda env list | grep -E "^${env_name}[[:space:]]+" | awk '{print $NF}')"
  
  if [[ -z "$env_path" ]]; then
    echo "Error: Conda environment '$env_name' not found."
    echo "Available environments:"
    conda env list
    exit 1
  fi

  if [[ ! -d "$env_path" ]]; then
    echo "Error: Environment path '$env_path' is not a valid directory."
    exit 1
  fi

  # Create activation hook
  local hook_dir="$env_path/etc/conda/activate.d"
  mkdir -p "$hook_dir"
  echo "➡ Adding activation hook → $hook_dir/specstory.sh"
  get_activation_hook > "$hook_dir/specstory.sh"
  VENV_HOOKS_ADDED+=("$hook_dir/specstory.sh")

  # Create deactivation hook
  local deactivate_dir="$env_path/etc/conda/deactivate.d"
  mkdir -p "$deactivate_dir"
  echo "➡ Adding deactivation hook → $deactivate_dir/specstory.sh"
  get_deactivation_hook > "$deactivate_dir/specstory.sh"
  VENV_HOOKS_ADDED+=("$deactivate_dir/specstory.sh")

  echo "✔ Hooks installed for conda environment: $env_name"
  echo "➡ Run: conda activate $env_name"
}

# Create venv hooks
setup_venv_hooks() {
  local venv_path="$1"
  venv_path="${venv_path/#\~/$HOME}"  # Expand ~ if present

  if [[ ! -d "$venv_path" ]]; then
    echo "Error: Directory '$venv_path' does not exist."
    exit 1
  fi

  local activate_script="$venv_path/bin/activate"
  if [[ ! -f "$activate_script" ]]; then
    echo "Error: activate script not found at '$activate_script'."
    exit 1
  fi

  # Add activation hook if not already present
  if ! grep -q "# SPECSTORY HOOK START" "$activate_script" 2>/dev/null; then
    echo "➡ Patching $activate_script"
    {
      echo ""
      echo "# SPECSTORY HOOK START"
      get_activation_hook
      echo "# SPECSTORY HOOK END"
    } >> "$activate_script"
    VENV_HOOKS_ADDED+=("$activate_script")
    echo "✔ Activation hook added to $activate_script"
  else
    echo "✔ Specstory hook already present in $activate_script"
  fi

  # Add deactivation hook
  local deactivate_script="$venv_path/bin/deactivate"
  if [[ -f "$deactivate_script" ]]; then
    # Standalone deactivate script exists
    if ! grep -q "# SPECSTORY DEACTIVATE HOOK" "$deactivate_script" 2>/dev/null; then
      echo "➡ Patching $deactivate_script"
      {
        echo ""
        echo "# SPECSTORY DEACTIVATE HOOK"
        get_deactivation_hook
      } >> "$deactivate_script"
      VENV_HOOKS_ADDED+=("$deactivate_script")
      echo "✔ Deactivation hook added to $deactivate_script"
    else
      echo "✔ Deactivation hook already present in $deactivate_script"
    fi
  else
    # Patch deactivate function in activate script
    if ! grep -q "# SPECSTORY DEACTIVATE HOOK" "$activate_script" 2>/dev/null; then
      if grep -q "^deactivate ()" "$activate_script"; then
        # macOS sed requires backup extension, Linux doesn't - use empty string for macOS
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '' '/^deactivate ()/,/^}/ {
            /^}/i\
    # SPECSTORY DEACTIVATE HOOK\
    unset -f claude 2>/dev/null || true
          }' "$activate_script"
        else
          sed -i '/^deactivate ()/,/^}/ {
            /^}/i\
    # SPECSTORY DEACTIVATE HOOK\
    unset -f claude 2>/dev/null || true
          }' "$activate_script"
        fi
        if [[ " ${VENV_HOOKS_ADDED[@]} " != *" $activate_script "* ]]; then
          VENV_HOOKS_ADDED+=("$activate_script")
        fi
        echo "✔ Deactivation hook added to deactivate function."
      else
        echo "⚠ Could not patch deactivate. Add manually to your deactivate workflow:"
        echo '   unset -f claude 2>/dev/null || true'
      fi
    else
      echo "✔ Deactivation hook already present."
    fi
  fi

  echo "➡ Run: source $activate_script"
}

# --- Step 6: Virtual environment activation hooks ---
echo
echo "═══════════════════════════════════════════════════════════════"
echo "VIRTUAL ENVIRONMENT SETUP"
echo "═══════════════════════════════════════════════════════════════"
echo
echo "Which virtual environment manager do you use?"
echo "  1) conda"
echo "  2) venv / virtualenv"
echo "  3) None / Manual setup"
echo
printf "Enter choice [1-3]: "
read VENV_CHOICE

case "$VENV_CHOICE" in
  1)
    echo
    echo "Enter the name of the conda environment where Specstory capture should be active."
    echo "(Example: base or your dev environment name)"
    printf "Environment name: "
    read ENV_NAME
    setup_conda_hooks "$ENV_NAME"
    ;;

  2)
    echo
    echo "Enter the full path to your virtual environment directory."
    echo "(Example: /path/to/project/.venv or ~/myproject/venv)"
    printf "Path: "
    read VENV_PATH
    setup_venv_hooks "$VENV_PATH"
    ;;

  3)
    echo
    echo "Manual setup instructions:"
    echo "─────────────────────────────────────────────────────────────"
    echo "Add the following lines to your shell profile or activate script:"
    echo
    echo "  $PATH_EXPORT"
    echo "  claude() {"
    echo "    # Filter \$HOME/bin from PATH to avoid infinite recursion"
    echo "    local filtered_path"
    echo "    filtered_path=\"\$(echo \"\$PATH\" | tr ':' '\\n' | grep -v \"^\${HOME}/bin\\\$\" | tr '\\n' ':' | sed 's/:\$//')\""
    echo "    PATH=\"\$filtered_path\" specstory run claude --no-cloud-sync \"\$@\""
    echo "  }"
    echo
    echo "To remove the function when deactivating, add:"
    echo "  unset -f claude 2>/dev/null || true"
    echo "─────────────────────────────────────────────────────────────"
    ;;

  *)
    echo "Invalid choice. Skipping virtual environment setup."
    echo "You can run this script again or configure manually."
    ;;
esac

# ============================================================================
# Installation Complete
# ============================================================================

# Disable cleanup trap on successful completion
trap - INT

echo
echo "Installation complete!"
echo "Your Specstory wrapper is ready."

# Final verification
echo "➡ Verifying installation..."

# Check wrapper files exist and are executable
if [[ ! -x "$WRAPPER_BIN" ]]; then
  echo "⚠ Warning: $WRAPPER_BIN is not executable"
fi
if [[ ! -x "$CLAUDE_WRAPPER_BIN" ]]; then
  echo "⚠ Warning: $CLAUDE_WRAPPER_BIN is not executable"
fi
if [[ ! -f "$PYTHON_WRAPPER" ]]; then
  echo "⚠ Warning: $PYTHON_WRAPPER was not installed"
fi

# Check PATH
CURRENT_CLAUDE="$(command -v claude || true)"
if [[ "$CURRENT_CLAUDE" != "$HOME/bin/claude" ]]; then
  echo "⚠ Warning: 'claude' command points to $CURRENT_CLAUDE"
  echo "   It should point to $HOME/bin/claude for SpecStory to work."
  echo "   Please restart your terminal or run: export PATH=\"\$HOME/bin:\$PATH\""
else
  echo "✔ 'claude' command correctly points to your wrapper."
fi

CURRENT_SPECSTORY="$(command -v specstory || true)"
if [[ "$CURRENT_SPECSTORY" != "$HOME/bin/specstory" ]]; then
  echo "⚠ Warning: 'specstory' command points to $CURRENT_SPECSTORY"
  echo "   After restarting your terminal, it should point to $HOME/bin/specstory"
else
  echo "✔ 'specstory' command correctly points to your wrapper."
fi

echo
echo "Restart your terminal or 'source ~/.zshrc' / 'source ~/.bashrc' to apply changes."
echo