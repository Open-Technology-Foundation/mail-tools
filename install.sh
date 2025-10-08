#!/bin/bash
# Comprehensive installation script for mailheader
# Copyright (C) 2025 Free Software Foundation, Inc.
# Licensed under GPL v3.0 or later

set -euo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob

VERSION='1.0.0'
SCRIPT_PATH=$(readlink -en -- "$0")
SCRIPT_NAME=${SCRIPT_PATH##*/}
readonly -- VERSION SCRIPT_PATH SCRIPT_NAME

declare -i VERBOSE=1

# Color definitions (only if terminal supports)
[[ -t 1 && -t 2 ]] && declare -- RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' CYAN=$'\033[0;36m' NC=$'\033[0m' || declare -- RED='' GREEN='' YELLOW='' CYAN='' NC=''
readonly -- RED GREEN YELLOW CYAN NC

# Core message function
_msg() {
  local -- prefix="$SCRIPT_NAME:" msg
  case "${FUNCNAME[1]}" in
    success) prefix+=" ${GREEN}✓${NC}" ;;
    warning) prefix+=" ${YELLOW}⚡${NC}" ;;
    info)    prefix+=" ${CYAN}◉${NC}" ;;
    error)   prefix+=" ${RED}✗${NC}" ;;
    *)       ;;
  esac
  for msg in "$@"; do printf '%s %s\n' "$prefix" "$msg"; done
}

# Messaging functions
vecho() { ((VERBOSE)) || return 0; _msg "$@"; }
success() { ((VERBOSE)) || return 0; >&2 _msg "$@"; }
warning() { ((VERBOSE)) || return 0; >&2 _msg "$@"; }
info() { ((VERBOSE)) || return 0; >&2 _msg "$@"; }
error() { >&2 _msg "$@"; }
die() { (($# > 1)) && error "${@:2}"; exit "${1:-0}"; }

# Default values
declare PREFIX=/usr/local
declare -i INSTALL_BUILTIN=0
declare -i BUILTIN_EXPLICITLY_REQUESTED=0
declare -i SKIP_BUILTIN=0
declare -i NON_INTERACTIVE=0
declare -i UNINSTALL=0
declare -i DRY_RUN=0

# Derived paths
declare BINDIR="$PREFIX"/bin
declare LOADABLE_DIR="$PREFIX"/lib/bash/loadables
# PROFILE_DIR intentionally hardcoded to /etc/profile.d for system-wide bash profile
# integration, regardless of PREFIX. This ensures builtins are available in all
# user sessions. To override, modify this line or use a custom install method.
declare PROFILE_DIR=/etc/profile.d
declare DOC_DIR="$PREFIX"/share/doc/mailheader
declare MAN_DIR="$PREFIX"/share/man/man1

show_help() {
  cat << 'EOF'
Mail Tools Installation Script
===============================

Usage: ./install.sh [OPTIONS]

Options:
  --help              Show this help message
  --builtin           Force installation of bash builtins (installs dependencies if needed)
  --no-builtin        Skip bash builtin installation
  --uninstall         Uninstall mail tools
  --prefix DIR        Installation prefix (default: /usr/local)
  --non-interactive   Don't prompt for user input
  --dry-run           Show what would be done without making changes

Installation Locations (with default prefix):
  Standalone binaries: /usr/local/bin/mailheader, mailmessage, mailheaderclean
  Scripts:             /usr/local/bin/mailgetaddresses, mailgetheaders, mailheaderclean-batch
                       (includes clean-email-headers symlink for backwards compatibility)
  Manpages:            /usr/local/share/man/man1/mailheader.1, mailmessage.1, mailheaderclean.1, mailgetaddresses.1
  Documentation:       /usr/local/share/doc/mailheader/
  Builtins (optional): /usr/local/lib/bash/loadables/mailheader.so, mailmessage.so, mailheaderclean.so
  Profile script:      /etc/profile.d/mail-tools.sh (always, regardless of --prefix)

Examples:
  ./install.sh                    # Interactive installation
  ./install.sh --builtin          # Install with builtins
  ./install.sh --no-builtin       # Install without builtins
  ./install.sh --uninstall        # Remove installation
  ./install.sh --prefix=/opt      # Install to /opt

EOF
  return 0
}

check_root() {
  ((EUID)) && die 1 'This script must be run as root or with sudo' || return 0
}

check_prerequisites() {
  info "Checking prerequisites..."

  # Check for gcc
  if ! command -v gcc &> /dev/null; then
    die 1 "'gcc' compiler not found. Please install 'build-essential' or 'gcc'."
  fi

  # Check for make
  if ! command -v make &> /dev/null; then
    die 1 "'make' not found. Please install 'make'."
  fi

  success "Prerequisites check passed"
}

check_builtin_support() {
  local -i has_support=0

  # Check for bash-builtins package (Debian/Ubuntu)
  if dpkg -l 2>/dev/null | grep -q "^ii.*bash-builtins"; then
    has_support=1
  fi

  # Check for bash header files
  if [[ -f /usr/include/bash/builtins.h ]]; then
    has_support=1
  fi

  return $((1 - has_support))
}

install_bash_builtins() {
  info "Installing bash-builtins package..."

  # Check if we're on a Debian/Ubuntu system
  if ! command -v apt-get &> /dev/null; then
    error "apt-get not found. Please install bash-builtins manually for your distribution."
    return 1
  fi

  if ((DRY_RUN)); then
    info "[DRY-RUN] Would run: apt-get install -y bash-builtins"
    return 0
  fi

  # Install bash-builtins
  if apt-get update && apt-get install -y bash-builtins; then
    success "bash-builtins package installed"
    return 0
  else
    error "Failed to install bash-builtins package"
    return 1
  fi
}

prompt_builtin_install() {
  if ((NON_INTERACTIVE)); then
    if ((INSTALL_BUILTIN)); then
      return 0
    else
      return 1
    fi
  fi

  echo ""
  echo "The bash loadable builtins provide 10-20x performance improvement"
  echo "for scripts that process multiple email files."
  echo ""
  read -p "Install bash loadable builtins? [Y/n] " -n 1 -r
  echo ""

  [[ $REPLY =~ ^[Nn]$ ]] || return 1
  return 0
}

build_standalone() {
  info "Building standalone binaries..."

  if ((DRY_RUN)); then
    info "[DRY-RUN] Would build: make standalone"
    return 0
  fi

  cd "$SCRIPT_DIR"
  make standalone || die 1 "Failed to build standalone binaries"
  success "Standalone binaries built (mailheader, mailmessage, mailheaderclean)"
}

build_builtin() {
  info "Building bash loadable builtins..."

  if ! check_builtin_support; then
    # If user explicitly requested --builtin, try to install dependencies
    if ((BUILTIN_EXPLICITLY_REQUESTED)); then
      warning "bash-builtins package not found, attempting to install..."
      if ! install_bash_builtins; then
        error "Failed to install bash-builtins package"
        error "Please install it manually:"
        error "  sudo apt-get install bash-builtins  # Debian/Ubuntu"
        return 1
      fi
      # Verify it was installed successfully
      if ! check_builtin_support; then
        error "bash-builtins installation did not provide required headers"
        return 1
      fi
    else
      error "Bash builtin support not found"
      error "Please install bash-builtins package:"
      error "  sudo apt-get install bash-builtins  # Debian/Ubuntu"
      return 1
    fi
  fi

  ((DRY_RUN==0)) || { info "[DRY-RUN] Would build: make loadable"; return 0; }

  cd "$SCRIPT_DIR"
  make loadable || {
    error "Failed to build bash builtins"
    return 1
  }
  success "Bash builtins built (mailheader.so, mailmessage.so, mailheaderclean.so)"
  return 0
}

install_standalone() {
  info "Installing standalone binaries and documentation..."

  if ((DRY_RUN)); then
    info "[DRY-RUN] Would install:"
    info "  ${BINDIR}/mailheader"
    info "  ${BINDIR}/mailmessage"
    info "  ${BINDIR}/mailheaderclean"
    info "  ${BINDIR}/mailgetaddresses"
    info "  ${BINDIR}/mailgetheaders"
    info "  ${BINDIR}/mailheaderclean-batch (script)"
    info "  ${BINDIR}/clean-email-headers -> mailheaderclean-batch (symlink)"
    info "  ${MAN_DIR}/mailheader.1"
    info "  ${MAN_DIR}/mailmessage.1"
    info "  ${MAN_DIR}/mailheaderclean.1"
    info "  ${MAN_DIR}/mailgetaddresses.1"
    info "  ${DOC_DIR}/README.md"
    info "  ${DOC_DIR}/benchmark.sh"
    info "  ${DOC_DIR}/benchmark_detailed.sh"
    return 0
  fi

  # Install binaries
  install -d "${BINDIR}"
  install -m 755 "${SCRIPT_DIR}/build/bin/mailheader" "${BINDIR}/" || die 1 "Failed to install mailheader binary"
  install -m 755 "${SCRIPT_DIR}/build/bin/mailmessage" "${BINDIR}/" || die 1 "Failed to install mailmessage binary"
  install -m 755 "${SCRIPT_DIR}/build/bin/mailheaderclean" "${BINDIR}/" || die 1 "Failed to install mailheaderclean binary"

  # Install scripts
  if [[ -f "${SCRIPT_DIR}/scripts/mailgetaddresses" ]]; then
    install -m 755 "${SCRIPT_DIR}/scripts/mailgetaddresses" "${BINDIR}/" || warning "Failed to install mailgetaddresses script"
  fi
  if [[ -f "${SCRIPT_DIR}/scripts/mailgetheaders" ]]; then
    install -m 755 "${SCRIPT_DIR}/scripts/mailgetheaders" "${BINDIR}/" || warning "Failed to install mailgetheaders script"
  fi
  if [[ -f "${SCRIPT_DIR}/scripts/mailheaderclean-batch" ]]; then
    install -m 755 "${SCRIPT_DIR}/scripts/mailheaderclean-batch" "${BINDIR}/" || warning "Failed to install mailheaderclean-batch script"
    # Create backwards-compatible symlink
    ln -sf "${BINDIR}/mailheaderclean-batch" "${BINDIR}/clean-email-headers" || warning "Failed to create clean-email-headers symlink"
  fi

  # Install manpages
  install -d "${MAN_DIR}"
  if [[ -f "${SCRIPT_DIR}/man/mailheader.1" ]]; then
    install -m 644 "${SCRIPT_DIR}/man/mailheader.1" "${MAN_DIR}/" || warning "Failed to install mailheader manpage"
  fi
  if [[ -f "${SCRIPT_DIR}/man/mailmessage.1" ]]; then
    install -m 644 "${SCRIPT_DIR}/man/mailmessage.1" "${MAN_DIR}/" || warning "Failed to install mailmessage manpage"
  fi
  if [[ -f "${SCRIPT_DIR}/man/mailheaderclean.1" ]]; then
    install -m 644 "${SCRIPT_DIR}/man/mailheaderclean.1" "${MAN_DIR}/" || warning "Failed to install mailheaderclean manpage"
  fi
  if [[ -f "${SCRIPT_DIR}/man/mailgetaddresses.1" ]]; then
    install -m 644 "${SCRIPT_DIR}/man/mailgetaddresses.1" "${MAN_DIR}/" || warning "Failed to install mailgetaddresses manpage"
  fi

  # Install documentation
  if [[ -f "${SCRIPT_DIR}/README.md" ]]; then
    install -d "${DOC_DIR}"
    install -m 644 "${SCRIPT_DIR}/README.md" "${DOC_DIR}/" || warning "Failed to install README"
  fi

  # Install benchmark scripts
  if [[ -f "${SCRIPT_DIR}/tools/benchmark.sh" ]]; then
    install -m 755 "${SCRIPT_DIR}/tools/benchmark.sh" "${DOC_DIR}/" || warning "Failed to install benchmark.sh"
  fi
  if [[ -f "${SCRIPT_DIR}/tools/benchmark_detailed.sh" ]]; then
    install -m 755 "${SCRIPT_DIR}/tools/benchmark_detailed.sh" "${DOC_DIR}/" || warning "Failed to install benchmark_detailed.sh"
  fi

  success "Standalone installation complete"
}

install_builtin() {
  info "Installing bash loadable builtins..."

  if ((DRY_RUN)); then
    info "[DRY-RUN] Would install:"
    info "  ${LOADABLE_DIR}/mailheader.so"
    info "  ${LOADABLE_DIR}/mailmessage.so"
    info "  ${LOADABLE_DIR}/mailheaderclean.so"
    info "  ${PROFILE_DIR}/mail-tools.sh"
    return 0
  fi

  # Install builtins
  install -d "${LOADABLE_DIR}"
  install -m 755 "${SCRIPT_DIR}/build/lib/mailheader.so" "${LOADABLE_DIR}/" || die 1 "Failed to install mailheader builtin"
  install -m 755 "${SCRIPT_DIR}/build/lib/mailmessage.so" "${LOADABLE_DIR}/" || die 1 "Failed to install mailmessage builtin"
  install -m 755 "${SCRIPT_DIR}/build/lib/mailheaderclean.so" "${LOADABLE_DIR}/" || die 1 "Failed to install mailheaderclean builtin"

  # Install profile script
  install -d "${PROFILE_DIR}"
  install -m 644 "${SCRIPT_DIR}/scripts/mail-tools.sh" "${PROFILE_DIR}/" || die 1 "Failed to install profile script"

  # Remove legacy mailheader.sh if it exists
  if [[ -f "${PROFILE_DIR}/mailheader.sh" ]]; then
    rm -f "${PROFILE_DIR}/mailheader.sh" || warning "Failed to remove legacy mailheader.sh"
    info "Removed legacy mailheader.sh profile script"
  fi

  success "Bash builtins installation complete"
}

update_man_database() {
  info "Updating man database..."

  if ((DRY_RUN)); then
    info "[DRY-RUN] Would run: mandb -q"
    return 0
  fi

  if command -v mandb &> /dev/null; then
    mandb -q 2>/dev/null || warning "Failed to update man database"
  fi
}

show_completion_message() {
  echo ""
  success "Installation complete!"
  echo ""
  echo "Installed files:"
  echo "  • Standalone binaries: ${BINDIR}/mailheader, ${BINDIR}/mailmessage, ${BINDIR}/mailheaderclean"
  echo "  • Scripts:             ${BINDIR}/mailgetaddresses, ${BINDIR}/mailgetheaders, ${BINDIR}/mailheaderclean-batch"
  echo "                         (includes ${BINDIR}/clean-email-headers symlink)"
  echo "  • Manpages:            ${MAN_DIR}/mailheader.1, ${MAN_DIR}/mailmessage.1, ${MAN_DIR}/mailheaderclean.1, ${MAN_DIR}/mailgetaddresses.1"
  echo "  • Documentation:       ${DOC_DIR}/"

  if ((INSTALL_BUILTIN)); then
    echo "  • Bash builtins:       ${LOADABLE_DIR}/mailheader.so, ${LOADABLE_DIR}/mailmessage.so, ${LOADABLE_DIR}/mailheaderclean.so"
    echo "  • Profile script:      ${PROFILE_DIR}/mail-tools.sh"
    echo ""
    echo "The bash builtins will be available in new bash sessions."
    echo "To use in your current session, run:"
    echo "  source ${PROFILE_DIR}/mail-tools.sh"
  fi

  echo ""
  echo "Verify installation:"
  echo "  which mailheader       # Check binaries"
  echo "  which mailmessage"
  echo "  which mailheaderclean"
  echo "  which mailgetaddresses # Check scripts"
  echo "  which mailgetheaders"
  echo "  which mailheaderclean-batch  # Check batch script"
  echo "  which clean-email-headers  # Check symlink (should point to mailheaderclean-batch)"
  echo "  man mailheader         # View manpages"
  echo "  man mailmessage"
  echo "  man mailheaderclean"
  echo "  man mailgetaddresses"

  if ((INSTALL_BUILTIN)); then
    echo "  help mailheader        # View builtin help (after sourcing profile)"
    echo "  help mailmessage"
    echo "  help mailheaderclean"
  fi

  echo ""
}

uninstall_files() {
  info "Uninstalling mail tools..."

  local -i files_removed=0

  if ((DRY_RUN)); then

 : <<'EOT'
     info "[DRY-RUN] Would remove:"
    [[ -f "${BINDIR}/mailheader" ]] && info "  ${BINDIR}/mailheader"
    [[ -f "${BINDIR}/mailmessage" ]] && info "  ${BINDIR}/mailmessage"
    [[ -f "${BINDIR}/mailheaderclean" ]] && info "  ${BINDIR}/mailheaderclean"
    [[ -f "${BINDIR}/mailgetaddresses" ]] && info "  ${BINDIR}/mailgetaddresses"
    [[ -f "${BINDIR}/mailgetheaders" ]] && info "  ${BINDIR}/mailgetheaders"
    [[ -f "${BINDIR}/mailheaderclean-batch" || -L "${BINDIR}/mailheaderclean-batch" ]] && info "  ${BINDIR}/mailheaderclean-batch (script)"
    [[ -f "${BINDIR}/clean-email-headers" || -L "${BINDIR}/clean-email-headers" ]] && info "  ${BINDIR}/clean-email-headers (symlink)"
    [[ -f "${MAN_DIR}/mailheader.1" ]] && info "  ${MAN_DIR}/mailheader.1"
    [[ -f "${MAN_DIR}/mailmessage.1" ]] && info "  ${MAN_DIR}/mailmessage.1"
    [[ -f "${MAN_DIR}/mailheaderclean.1" ]] && info "  ${MAN_DIR}/mailheaderclean.1"
    [[ -f "${MAN_DIR}/mailgetaddresses.1" ]] && info "  ${MAN_DIR}/mailgetaddresses.1"
    [[ -f "${LOADABLE_DIR}/mailheader.so" ]] && info "  ${LOADABLE_DIR}/mailheader.so"
    [[ -f "${LOADABLE_DIR}/mailmessage.so" ]] && info "  ${LOADABLE_DIR}/mailmessage.so"
    [[ -f "${LOADABLE_DIR}/mailheaderclean.so" ]] && info "  ${LOADABLE_DIR}/mailheaderclean.so"
    [[ -f "${PROFILE_DIR}/mail-tools.sh" ]] && info "  ${PROFILE_DIR}/mail-tools.sh"
    [[ -f "${PROFILE_DIR}/mailheader.sh" ]] && info "  ${PROFILE_DIR}/mailheader.sh (legacy)"
    [[ -d "${DOC_DIR}" ]] && info "  ${DOC_DIR}/"
EOT

    info "[DRY-RUN] Would remove:"
    for path in \
      "${BINDIR}/mailheader" \
      "${BINDIR}/mailmessage" \
      "${BINDIR}/mailheaderclean" \
      "${BINDIR}/mailgetaddresses" \
      "${BINDIR}/mailgetheaders" \
      "${BINDIR}/mailheaderclean-batch" \
      "${BINDIR}/clean-email-headers" \
      "${MAN_DIR}/mailheader.1" \
      "${MAN_DIR}/mailmessage.1" \
      "${MAN_DIR}/mailheaderclean.1" \
      "${MAN_DIR}/mailgetaddresses.1" \
      "${LOADABLE_DIR}/mailheader.so" \
      "${LOADABLE_DIR}/mailmessage.so" \
      "${LOADABLE_DIR}/mailheaderclean.so" \
      "${PROFILE_DIR}/mail-tools.sh" \
      "${PROFILE_DIR}/mailheader.sh" \
      "${DOC_DIR}"; do
         if [[ -L $path ]]; then
           info "    $path (symlink)"
         elif [[ -f $path ]]; then
           info "    $path"
         elif [[ -d $path ]]; then
           info "    $path (directory)"
         fi
      done

    return 0
  fi

  # Remove binaries
  if [[ -f "${BINDIR}/mailheader" ]]; then
    rm -f "${BINDIR}/mailheader" && ((files_removed+=1))
  fi
  if [[ -f "${BINDIR}/mailmessage" ]]; then
    rm -f "${BINDIR}/mailmessage" && ((files_removed+=1))
  fi
  if [[ -f "${BINDIR}/mailheaderclean" ]]; then
    rm -f "${BINDIR}/mailheaderclean" && ((files_removed+=1))
  fi
  if [[ -f "${BINDIR}/mailgetaddresses" ]]; then
    rm -f "${BINDIR}/mailgetaddresses" && ((files_removed+=1))
  fi
  if [[ -f "${BINDIR}/mailgetheaders" ]]; then
    rm -f "${BINDIR}/mailgetheaders" && ((files_removed+=1))
  fi

  # Remove mailheaderclean-batch script and backwards-compatible symlink
  if [[ -f "${BINDIR}/mailheaderclean-batch" || -L "${BINDIR}/mailheaderclean-batch" ]]; then
    rm -f "${BINDIR}/mailheaderclean-batch" && ((files_removed+=1))
  fi
  if [[ -f "${BINDIR}/clean-email-headers" || -L "${BINDIR}/clean-email-headers" ]]; then
    rm -f "${BINDIR}/clean-email-headers" && ((files_removed+=1))
  fi

  # Remove manpages
  if [[ -f "${MAN_DIR}/mailheader.1" ]]; then
    rm -f "${MAN_DIR}/mailheader.1" && ((files_removed+=1))
  fi
  if [[ -f "${MAN_DIR}/mailmessage.1" ]]; then
    rm -f "${MAN_DIR}/mailmessage.1" && ((files_removed+=1))
  fi
  if [[ -f "${MAN_DIR}/mailheaderclean.1" ]]; then
    rm -f "${MAN_DIR}/mailheaderclean.1" && ((files_removed+=1))
  fi
  if [[ -f "${MAN_DIR}/mailgetaddresses.1" ]]; then
    rm -f "${MAN_DIR}/mailgetaddresses.1" && ((files_removed+=1))
  fi

  # Remove builtins
  if [[ -f "${LOADABLE_DIR}/mailheader.so" ]]; then
    rm -f "${LOADABLE_DIR}/mailheader.so" && ((files_removed+=1))
  fi
  if [[ -f "${LOADABLE_DIR}/mailmessage.so" ]]; then
    rm -f "${LOADABLE_DIR}/mailmessage.so" && ((files_removed+=1))
  fi
  if [[ -f "${LOADABLE_DIR}/mailheaderclean.so" ]]; then
    rm -f "${LOADABLE_DIR}/mailheaderclean.so" && ((files_removed+=1))
  fi

  # Remove profile scripts (both new and legacy)
  if [[ -f "${PROFILE_DIR}/mail-tools.sh" ]]; then
    rm -f "${PROFILE_DIR}/mail-tools.sh" && ((files_removed+=1))
  fi
  if [[ -f "${PROFILE_DIR}/mailheader.sh" ]]; then
    rm -f "${PROFILE_DIR}/mailheader.sh" && ((files_removed+=1))
  fi

  # Remove documentation directory
  if [[ -d "${DOC_DIR}" ]]; then
    rm -rf "${DOC_DIR}" && ((files_removed+=1))
  fi

  if ((files_removed)); then
    update_man_database
    success "Uninstalled $files_removed file(s)/directory(ies)"
    echo ""
    echo "You may need to restart bash sessions for changes to take effect."
  else
    warning "No mail tools installation found"
  fi
}

# Parse command-line arguments
while (($#)); do
  case $1 in
    --help|-h)
      show_help; exit 0
      ;;
    --builtin)
      INSTALL_BUILTIN=1
      BUILTIN_EXPLICITLY_REQUESTED=1
      ;;
    --no-builtin)
      SKIP_BUILTIN=1
      ;;
    --uninstall)
      UNINSTALL=1
      ;;
    --prefix)
      shift
      PREFIX="$1"
      BINDIR="$PREFIX"/bin
      LOADABLE_DIR="$PREFIX"/lib/bash/loadables
      DOC_DIR="$PREFIX"/share/doc/mailheader
      MAN_DIR="$PREFIX"/share/man/man1
      # Note: PROFILE_DIR stays at /etc/profile.d for system-wide access
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -a|--auto-all)
      UNINSTALL=0
      DRY_RUN=0
      VERBOSE=0
      NON_INTERACTIVE=1
      INSTALL_BUILTIN=1
      BUILTIN_EXPLICITLY_REQUESTED=1
      ;;
    *)
      error "Unknown option '$1'"
      echo
      show_help 1
      ;;
  esac
  shift
done

# Main execution
main() {
  echo "Mail Tools Installation Script"
  echo "=============================="
  echo

  check_root
  check_prerequisites

  if ((UNINSTALL)); then
    uninstall_files
    return 0
  fi

  # Check if binaries are already built
  if [[ ! -f "${SCRIPT_DIR}/build/bin/mailheader" ]] || [[ ! -f "${SCRIPT_DIR}/build/bin/mailmessage" ]] || [[ ! -f "${SCRIPT_DIR}/build/bin/mailheaderclean" ]]; then
    build_standalone
  else
    info "Standalone binaries already built"
  fi

  # Determine if we should install builtin
  if ((SKIP_BUILTIN)); then
    INSTALL_BUILTIN=0
  elif ((INSTALL_BUILTIN == 0)); then
    if prompt_builtin_install; then
      INSTALL_BUILTIN=1
    fi
  fi

  # Build builtin if needed
  if ((INSTALL_BUILTIN)); then
    if [[ ! -f "${SCRIPT_DIR}/build/lib/mailheader.so" ]] || [[ ! -f "${SCRIPT_DIR}/build/lib/mailmessage.so" ]] || [[ ! -f "${SCRIPT_DIR}/build/lib/mailheaderclean.so" ]]; then
      if ! build_builtin; then
        warning "Skipping builtin installation due to build failure"
        INSTALL_BUILTIN=0
      fi
    else
      info "Bash builtins already built"
    fi
  fi

  # Install files
  install_standalone

  if ((INSTALL_BUILTIN)); then
    install_builtin
  fi

  # Update man database
  update_man_database

  # Show completion message
  if ((DRY_RUN == 0)); then
    show_completion_message
  else
    echo
    info "[DRY-RUN] No changes were made"
  fi

  return 0
}

main "$@"
#fin
