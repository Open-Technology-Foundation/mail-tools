#
# Makefile for mailheader - standalone binary and bash loadable builtin
#
# Copyright (C) 2025 Free Software Foundation, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

# Compiler and flags
CC = gcc
CFLAGS = -Wall -O2
LDFLAGS =

# Bash builtin specific
BASH_INCLUDE = /usr/include/bash
BASH_BUILTINS = /usr/include/bash/builtins
BASH_INCLUDE_DIR = /usr/include/bash/include
SHOBJ_CFLAGS = -fPIC -I$(BASH_INCLUDE) -I$(BASH_BUILTINS) -I$(BASH_INCLUDE_DIR)
SHOBJ_LDFLAGS = -shared

# Installation directories
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
LOADABLE_DIR = $(PREFIX)/lib/bash/loadables
PROFILE_DIR = /etc/profile.d
DOC_DIR = $(PREFIX)/share/doc/mailheader
MAN_DIR = $(PREFIX)/share/man/man1

# Targets
MAILHEADER_BIN = mailheader
MAILHEADER_SO = mailheader.so
MAILMESSAGE_BIN = mailmessage
MAILMESSAGE_SO = mailmessage.so
MAILHEADERCLEAN_BIN = mailheaderclean
MAILHEADERCLEAN_SO = mailheaderclean.so

.PHONY: all all-mailheader all-mailmessage all-mailheaderclean standalone loadable clean install install-standalone install-loadable uninstall help

# Default target: build all utilities
all: all-mailheader all-mailmessage all-mailheaderclean

# Build mailheader (both versions)
all-mailheader: $(MAILHEADER_BIN) $(MAILHEADER_SO)

# Build mailmessage (both versions)
all-mailmessage: $(MAILMESSAGE_BIN) $(MAILMESSAGE_SO)

# Build mailheaderclean (both versions)
all-mailheaderclean: $(MAILHEADERCLEAN_BIN) $(MAILHEADERCLEAN_SO)

# Legacy targets for compatibility
standalone: $(MAILHEADER_BIN) $(MAILMESSAGE_BIN) $(MAILHEADERCLEAN_BIN)
loadable: $(MAILHEADER_SO) $(MAILMESSAGE_SO) $(MAILHEADERCLEAN_SO)

# Build mailheader standalone
$(MAILHEADER_BIN): mailheader.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

# Build mailheader loadable
$(MAILHEADER_SO): mailheader_loadable.o
	$(CC) $(SHOBJ_LDFLAGS) -o $@ $<

mailheader_loadable.o: mailheader_loadable.c
	$(CC) $(SHOBJ_CFLAGS) $(CFLAGS) -c -o $@ $<

# Build mailmessage standalone
$(MAILMESSAGE_BIN): mailmessage.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

# Build mailmessage loadable
$(MAILMESSAGE_SO): mailmessage_loadable.o
	$(CC) $(SHOBJ_LDFLAGS) -o $@ $<

mailmessage_loadable.o: mailmessage_loadable.c
	$(CC) $(SHOBJ_CFLAGS) $(CFLAGS) -c -o $@ $<

# Build mailheaderclean standalone
$(MAILHEADERCLEAN_BIN): mailheaderclean.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

# Build mailheaderclean loadable
$(MAILHEADERCLEAN_SO): mailheaderclean_loadable.o
	$(CC) $(SHOBJ_LDFLAGS) -o $@ $<

mailheaderclean_loadable.o: mailheaderclean_loadable.c
	$(CC) $(SHOBJ_CFLAGS) $(CFLAGS) -c -o $@ $<

# Install everything (all utilities, both versions)
install: install-standalone install-loadable
	@echo "Installation complete!"
	@echo "The mailheader, mailmessage, and mailheaderclean builtins will be available in new bash sessions."
	@echo "For the current session, run: source /etc/profile.d/mail-tools.sh"

# Install standalone binaries only
install-standalone: $(MAILHEADER_BIN) $(MAILMESSAGE_BIN) $(MAILHEADERCLEAN_BIN)
	@echo "Installing standalone binaries..."
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 $(MAILHEADER_BIN) $(DESTDIR)$(BINDIR)/
	install -m 755 $(MAILMESSAGE_BIN) $(DESTDIR)$(BINDIR)/
	install -m 755 $(MAILHEADERCLEAN_BIN) $(DESTDIR)$(BINDIR)/
	@if [ -f mailheader.1 ]; then \
		echo "Installing manpages..."; \
		install -d $(DESTDIR)$(MAN_DIR); \
		install -m 644 mailheader.1 $(DESTDIR)$(MAN_DIR)/; \
	fi
	@if [ -f mailmessage.1 ]; then \
		install -m 644 mailmessage.1 $(DESTDIR)$(MAN_DIR)/; \
	fi
	@if [ -f mailheaderclean.1 ]; then \
		install -m 644 mailheaderclean.1 $(DESTDIR)$(MAN_DIR)/; \
	fi

# Install loadable builtins and configuration
install-loadable: $(MAILHEADER_SO) $(MAILMESSAGE_SO) $(MAILHEADERCLEAN_SO)
	@echo "Installing bash loadable builtins..."
	install -d $(DESTDIR)$(LOADABLE_DIR)
	install -m 755 $(MAILHEADER_SO) $(DESTDIR)$(LOADABLE_DIR)/
	install -m 755 $(MAILMESSAGE_SO) $(DESTDIR)$(LOADABLE_DIR)/
	install -m 755 $(MAILHEADERCLEAN_SO) $(DESTDIR)$(LOADABLE_DIR)/
	@echo "Installing profile configuration..."
	install -d $(DESTDIR)$(PROFILE_DIR)
	install -m 644 mail-tools.sh $(DESTDIR)$(PROFILE_DIR)/
	@if [ -f README.md ]; then \
		echo "Installing documentation..."; \
		install -d $(DESTDIR)$(DOC_DIR); \
		install -m 644 README.md $(DESTDIR)$(DOC_DIR)/; \
	fi

# Uninstall everything
uninstall:
	@echo "Uninstalling mail tools..."
	rm -f $(DESTDIR)$(BINDIR)/$(MAILHEADER_BIN)
	rm -f $(DESTDIR)$(BINDIR)/$(MAILMESSAGE_BIN)
	rm -f $(DESTDIR)$(BINDIR)/$(MAILHEADERCLEAN_BIN)
	rm -f $(DESTDIR)$(LOADABLE_DIR)/$(MAILHEADER_SO)
	rm -f $(DESTDIR)$(LOADABLE_DIR)/$(MAILMESSAGE_SO)
	rm -f $(DESTDIR)$(LOADABLE_DIR)/$(MAILHEADERCLEAN_SO)
	rm -f $(DESTDIR)$(PROFILE_DIR)/mail-tools.sh
	rm -f $(DESTDIR)$(PROFILE_DIR)/mailheader.sh
	rm -f $(DESTDIR)$(MAN_DIR)/mailheader.1
	rm -f $(DESTDIR)$(MAN_DIR)/mailmessage.1
	rm -f $(DESTDIR)$(MAN_DIR)/mailheaderclean.1
	rm -rf $(DESTDIR)$(DOC_DIR)
	@echo "Uninstall complete. You may need to restart bash sessions."

# Clean build artifacts
clean:
	rm -f $(MAILHEADER_BIN) $(MAILHEADER_SO) $(MAILMESSAGE_BIN) $(MAILMESSAGE_SO) $(MAILHEADERCLEAN_BIN) $(MAILHEADERCLEAN_SO) *.o

# Help target
help:
	@echo "Mail Tools Build System"
	@echo "======================="
	@echo ""
	@echo "Targets:"
	@echo "  all                   - Build all utilities (mailheader + mailmessage + mailheaderclean) (default)"
	@echo "  all-mailheader        - Build mailheader (both standalone and loadable)"
	@echo "  all-mailmessage       - Build mailmessage (both standalone and loadable)"
	@echo "  all-mailheaderclean   - Build mailheaderclean (both standalone and loadable)"
	@echo "  standalone            - Build all standalone binaries"
	@echo "  loadable              - Build all bash loadable builtins"
	@echo "  install               - Install all utilities (requires sudo)"
	@echo "  install-standalone    - Install standalone binaries only (requires sudo)"
	@echo "  install-loadable      - Install loadable builtins only (requires sudo)"
	@echo "  uninstall             - Remove all installed files (requires sudo)"
	@echo "  clean                 - Remove build artifacts"
	@echo "  help                  - Show this help message"
	@echo ""
	@echo "Installation directories:"
	@echo "  Standalone binaries: $(BINDIR)"
	@echo "  Loadable builtins:   $(LOADABLE_DIR)"
	@echo "  Profile script:      $(PROFILE_DIR)"
	@echo "  Documentation:       $(DOC_DIR)"
	@echo "  Manpages:            $(MAN_DIR)"
	@echo ""
	@echo "Usage examples:"
	@echo "  make                - Build all utilities"
	@echo "  sudo make install   - Install system-wide"
	@echo "  make clean          - Clean build files"
