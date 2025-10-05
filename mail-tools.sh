# shellcheck shell=bash
# mail-tools bash loadable builtins configuration
# This file is automatically sourced by bash login shells
# Installed to /etc/profile.d/mail-tools.sh

# Set BASH_LOADABLES_PATH to include mail-tools builtin directory
# This path is exported and inherited by all child processes
if [ -d /usr/local/lib/bash/loadables ]; then
    if [ -z "$BASH_LOADABLES_PATH" ]; then
        export BASH_LOADABLES_PATH="/usr/local/lib/bash/loadables"
    else
        # Prepend if not already in path
        case ":$BASH_LOADABLES_PATH:" in
            *:/usr/local/lib/bash/loadables:*) ;;
            *) export BASH_LOADABLES_PATH="/usr/local/lib/bash/loadables:$BASH_LOADABLES_PATH" ;;
        esac
    fi
fi

# Auto-load mail-tools builtins for interactive shells only
# Non-interactive scripts and cron jobs must explicitly enable them
if [ -n "$PS1" ]; then
    # This is an interactive shell
    enable -f mailheader.so mailheader 2>/dev/null || true
    enable -f mailmessage.so mailmessage 2>/dev/null || true
    enable -f mailheaderclean.so mailheaderclean 2>/dev/null || true
fi

# Usage notes for scripts and cron jobs:
#
# To use mail-tools in a non-interactive script or cron job, add these lines
# near the top of your script:
#
#   enable -f mailheader.so mailheader 2>/dev/null || true
#   enable -f mailmessage.so mailmessage 2>/dev/null || true
#   enable -f mailheaderclean.so mailheaderclean 2>/dev/null || true
#
# Or use the one-liner for cron:
#
#   bash -c 'enable -f mailheader.so mailheader; mailheader /path/to/file'
#   bash -c 'enable -f mailmessage.so mailmessage; mailmessage /path/to/file'
#   bash -c 'enable -f mailheaderclean.so mailheaderclean; mailheaderclean /path/to/file'
#
# The BASH_LOADABLES_PATH is already set globally, so you only need to
# explicitly enable the builtins.
