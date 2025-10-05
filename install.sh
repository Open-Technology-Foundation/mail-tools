#!/bin/bash
# Comprehensive installation script for mailheader
# Copyright (C) 2025 Free Software Foundation, Inc.
# Licensed under GPL v3.0 or later

set -euo pipefail

# Color codes (if terminal supports it)
if [[ -t 1 ]]; then
  declare -r RED='\033[0;31m'
  declare -r GREEN='\033[0;32m'
  declare -r YELLOW='\033[1;33m'
  declare -r BLUE='\033[0;34m'
  declare -r NC='\033[0m'
else
  declare -r RED=''
  declare -r GREEN=''
  declare -r YELLOW=''
  declare -r BLUE=''
  declare -r NC=''
fi

# Default values
declare PREFIX="/usr/local"
declare -i INSTALL_BUILTIN=0
declare -i BUILTIN_EXPLICITLY_REQUESTED=0
declare -i SKIP_BUILTIN=0
declare -i NON_INTERACTIVE=0
declare -i UNINSTALL=0
declare -i DRY_RUN=0

# Derived paths
declare BINDIR="${PREFIX}/bin"
declare LOADABLE_DIR="${PREFIX}/lib/bash/loadables"
declare PROFILE_DIR="/etc/profile.d"
declare DOC_DIR="${PREFIX}/share/doc/mailheader"
declare MAN_DIR="${PREFIX}/share/man/man1"

# Script directory
declare SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -r SCRIPT_DIR

# Functions
info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

die() {
  error "$*"
  exit 1
}

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
  Manpages:            /usr/local/share/man/man1/mailheader.1, mailmessage.1, mailheaderclean.1
  Documentation:       /usr/local/share/doc/mailheader/
  Builtins (optional): /usr/local/lib/bash/loadables/mailheader.so, mailmessage.so, mailheaderclean.so
  Profile script:      /etc/profile.d/mail-tools.sh

Examples:
  ./install.sh                    # Interactive installation
  ./install.sh --builtin          # Install with builtins
  ./install.sh --no-builtin       # Install without builtins
  ./install.sh --uninstall        # Remove installation
  ./install.sh --prefix=/opt      # Install to /opt

EOF
}

check_root() {
  if ((EUID != 0)); then
    die "This script must be run as root or with sudo"
  fi
}

check_prerequisites() {
  info "Checking prerequisites..."

  # Check for gcc
  if ! command -v gcc &> /dev/null; then
    die "'gcc' compiler not found. Please install 'build-essential' or 'gcc'."
  fi

  # Check for make
  if ! command -v make &> /dev/null; then
    die "'make' not found. Please install 'make'."
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

  if [[ $REPLY =~ ^[Nn]$ ]]; then
    return 1
  fi
  return 0
}

build_standalone() {
  info "Building standalone binaries..."

  if ((DRY_RUN)); then
    info "[DRY-RUN] Would build: make standalone"
    return 0
  fi

  cd "$SCRIPT_DIR"
  make standalone || die "Failed to build standalone binaries"
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

  if ((DRY_RUN)); then
    info "[DRY-RUN] Would build: make loadable"
    return 0
  fi

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
    info "  ${MAN_DIR}/mailheader.1"
    info "  ${MAN_DIR}/mailmessage.1"
    info "  ${MAN_DIR}/mailheaderclean.1"
    info "  ${DOC_DIR}/README.md"
    info "  ${DOC_DIR}/benchmark.sh"
    info "  ${DOC_DIR}/benchmark_detailed.sh"
    return 0
  fi

  # Install binaries
  install -d "${BINDIR}"
  install -m 755 "${SCRIPT_DIR}/mailheader" "${BINDIR}/" || die "Failed to install mailheader binary"
  install -m 755 "${SCRIPT_DIR}/mailmessage" "${BINDIR}/" || die "Failed to install mailmessage binary"
  install -m 755 "${SCRIPT_DIR}/mailheaderclean" "${BINDIR}/" || die "Failed to install mailheaderclean binary"

  # Install manpages
  install -d "${MAN_DIR}"
  if [[ -f "${SCRIPT_DIR}/mailheader.1" ]]; then
    install -m 644 "${SCRIPT_DIR}/mailheader.1" "${MAN_DIR}/" || warning "Failed to install mailheader manpage"
  fi
  if [[ -f "${SCRIPT_DIR}/mailmessage.1" ]]; then
    install -m 644 "${SCRIPT_DIR}/mailmessage.1" "${MAN_DIR}/" || warning "Failed to install mailmessage manpage"
  fi
  if [[ -f "${SCRIPT_DIR}/mailheaderclean.1" ]]; then
    install -m 644 "${SCRIPT_DIR}/mailheaderclean.1" "${MAN_DIR}/" || warning "Failed to install mailheaderclean manpage"
  fi

  # Install documentation
  if [[ -f "${SCRIPT_DIR}/README.md" ]]; then
    install -d "${DOC_DIR}"
    install -m 644 "${SCRIPT_DIR}/README.md" "${DOC_DIR}/" || warning "Failed to install README"
  fi

  # Install benchmark scripts
  if [[ -f "${SCRIPT_DIR}/benchmark.sh" ]]; then
    install -m 755 "${SCRIPT_DIR}/benchmark.sh" "${DOC_DIR}/" || warning "Failed to install benchmark.sh"
  fi
  if [[ -f "${SCRIPT_DIR}/benchmark_detailed.sh" ]]; then
    install -m 755 "${SCRIPT_DIR}/benchmark_detailed.sh" "${DOC_DIR}/" || warning "Failed to install benchmark_detailed.sh"
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
  install -m 755 "${SCRIPT_DIR}/mailheader.so" "${LOADABLE_DIR}/" || die "Failed to install mailheader builtin"
  install -m 755 "${SCRIPT_DIR}/mailmessage.so" "${LOADABLE_DIR}/" || die "Failed to install mailmessage builtin"
  install -m 755 "${SCRIPT_DIR}/mailheaderclean.so" "${LOADABLE_DIR}/" || die "Failed to install mailheaderclean builtin"

  # Install profile script
  install -d "${PROFILE_DIR}"
  install -m 644 "${SCRIPT_DIR}/mail-tools.sh" "${PROFILE_DIR}/" || die "Failed to install profile script"

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
  echo "  • Manpages:            ${MAN_DIR}/mailheader.1, ${MAN_DIR}/mailmessage.1, ${MAN_DIR}/mailheaderclean.1"
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
  echo "  man mailheader         # View manpages"
  echo "  man mailmessage"
  echo "  man mailheaderclean"

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
    info "[DRY-RUN] Would remove:"
    [[ -f "${BINDIR}/mailheader" ]] && info "  ${BINDIR}/mailheader"
    [[ -f "${BINDIR}/mailmessage" ]] && info "  ${BINDIR}/mailmessage"
    [[ -f "${BINDIR}/mailheaderclean" ]] && info "  ${BINDIR}/mailheaderclean"
    [[ -f "${MAN_DIR}/mailheader.1" ]] && info "  ${MAN_DIR}/mailheader.1"
    [[ -f "${MAN_DIR}/mailmessage.1" ]] && info "  ${MAN_DIR}/mailmessage.1"
    [[ -f "${MAN_DIR}/mailheaderclean.1" ]] && info "  ${MAN_DIR}/mailheaderclean.1"
    [[ -f "${LOADABLE_DIR}/mailheader.so" ]] && info "  ${LOADABLE_DIR}/mailheader.so"
    [[ -f "${LOADABLE_DIR}/mailmessage.so" ]] && info "  ${LOADABLE_DIR}/mailmessage.so"
    [[ -f "${LOADABLE_DIR}/mailheaderclean.so" ]] && info "  ${LOADABLE_DIR}/mailheaderclean.so"
    [[ -f "${PROFILE_DIR}/mail-tools.sh" ]] && info "  ${PROFILE_DIR}/mail-tools.sh"
    [[ -f "${PROFILE_DIR}/mailheader.sh" ]] && info "  ${PROFILE_DIR}/mailheader.sh (legacy)"
    [[ -d "${DOC_DIR}" ]] && info "  ${DOC_DIR}/"
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
      show_help
      exit 0
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
      BINDIR="${PREFIX}/bin"
      LOADABLE_DIR="${PREFIX}/lib/bash/loadables"
      DOC_DIR="${PREFIX}/share/doc/mailheader"
      MAN_DIR="${PREFIX}/share/man/man1"
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    *)
      error "Unknown option: $1"
      echo ""
      show_help
      exit 1
      ;;
  esac
  shift
done

# Main execution
main() {
  echo "Mail Tools Installation Script"
  echo "=============================="
  echo ""

  check_root
  check_prerequisites

  if ((UNINSTALL)); then
    uninstall_files
    exit 0
  fi

  # Check if binaries are already built
  if [[ ! -f "${SCRIPT_DIR}/mailheader" ]] || [[ ! -f "${SCRIPT_DIR}/mailmessage" ]] || [[ ! -f "${SCRIPT_DIR}/mailheaderclean" ]]; then
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
    if [[ ! -f "${SCRIPT_DIR}/mailheader.so" ]] || [[ ! -f "${SCRIPT_DIR}/mailmessage.so" ]] || [[ ! -f "${SCRIPT_DIR}/mailheaderclean.so" ]]; then
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
    echo ""
    info "[DRY-RUN] No changes were made"
  fi
}

main

#fin
