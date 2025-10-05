# shellcheck shell=bash
# mailheader bash loadable builtin configuration
# This file is automatically sourced by bash login shells
# Installed to /etc/profile.d/mailheader.sh

# Set BASH_LOADABLES_PATH to include mailheader builtin directory
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

# Auto-load mailheader builtin for interactive shells only
# Non-interactive scripts and cron jobs must explicitly enable it
if [ -n "$PS1" ]; then
    # This is an interactive shell
    enable -f mailheader.so mailheader 2>/dev/null || true
fi

# Usage notes for scripts and cron jobs:
#
# To use mailheader in a non-interactive script or cron job, add this line
# near the top of your script:
#
#   enable -f mailheader.so mailheader 2>/dev/null || true
#
# Or use the one-liner for cron:
#
#   bash -c 'enable -f mailheader.so mailheader; mailheader /path/to/file'
#
# The BASH_LOADABLES_PATH is already set globally, so you only need to
# explicitly enable the builtin.
