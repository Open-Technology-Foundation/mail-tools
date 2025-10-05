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
STANDALONE = mailheader
LOADABLE = mailheader.so

.PHONY: all standalone loadable clean install install-standalone install-loadable uninstall help

# Default target: build both versions
all: standalone loadable

# Build standalone executable
standalone: $(STANDALONE)

$(STANDALONE): mailheader.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

# Build loadable builtin
loadable: $(LOADABLE)

$(LOADABLE): mailheader_loadable.o
	$(CC) $(SHOBJ_LDFLAGS) -o $@ $<

mailheader_loadable.o: mailheader_loadable.c
	$(CC) $(SHOBJ_CFLAGS) $(CFLAGS) -c -o $@ $<

# Install everything (both standalone and loadable)
install: install-standalone install-loadable
	@echo "Installation complete!"
	@echo "The mailheader builtin will be available in new bash sessions."
	@echo "For the current session, run: source /etc/profile.d/mailheader.sh"

# Install standalone binary only
install-standalone: standalone
	@echo "Installing standalone binary..."
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 $(STANDALONE) $(DESTDIR)$(BINDIR)/
	@if [ -f mailheader.1 ]; then \
		echo "Installing manpage..."; \
		install -d $(DESTDIR)$(MAN_DIR); \
		install -m 644 mailheader.1 $(DESTDIR)$(MAN_DIR)/; \
	fi

# Install loadable builtin and configuration
install-loadable: loadable
	@echo "Installing bash loadable builtin..."
	install -d $(DESTDIR)$(LOADABLE_DIR)
	install -m 755 $(LOADABLE) $(DESTDIR)$(LOADABLE_DIR)/
	@echo "Installing profile configuration..."
	install -d $(DESTDIR)$(PROFILE_DIR)
	install -m 644 mailheader.sh $(DESTDIR)$(PROFILE_DIR)/
	@if [ -f README.md ]; then \
		echo "Installing documentation..."; \
		install -d $(DESTDIR)$(DOC_DIR); \
		install -m 644 README.md $(DESTDIR)$(DOC_DIR)/; \
	fi

# Uninstall everything
uninstall:
	@echo "Uninstalling mailheader..."
	rm -f $(DESTDIR)$(BINDIR)/$(STANDALONE)
	rm -f $(DESTDIR)$(LOADABLE_DIR)/$(LOADABLE)
	rm -f $(DESTDIR)$(PROFILE_DIR)/mailheader.sh
	rm -f $(DESTDIR)$(MAN_DIR)/mailheader.1
	rm -rf $(DESTDIR)$(DOC_DIR)
	@echo "Uninstall complete. You may need to restart bash sessions."

# Clean build artifacts
clean:
	rm -f $(STANDALONE) $(LOADABLE) *.o

# Help target
help:
	@echo "Mailheader Build System"
	@echo "======================="
	@echo ""
	@echo "Targets:"
	@echo "  all                 - Build both standalone and loadable versions (default)"
	@echo "  standalone          - Build standalone binary only"
	@echo "  loadable            - Build bash loadable builtin only"
	@echo "  install             - Install both versions (requires sudo)"
	@echo "  install-standalone  - Install standalone binary only (requires sudo)"
	@echo "  install-loadable    - Install loadable builtin only (requires sudo)"
	@echo "  uninstall           - Remove all installed files (requires sudo)"
	@echo "  clean               - Remove build artifacts"
	@echo "  help                - Show this help message"
	@echo ""
	@echo "Installation directories:"
	@echo "  Standalone binary:  $(BINDIR)"
	@echo "  Loadable builtin:   $(LOADABLE_DIR)"
	@echo "  Profile script:     $(PROFILE_DIR)"
	@echo "  Documentation:      $(DOC_DIR)"
	@echo "  Manpage:            $(MAN_DIR)"
	@echo ""
	@echo "Usage examples:"
	@echo "  make                - Build both versions"
	@echo "  sudo make install   - Install system-wide"
	@echo "  make clean          - Clean build files"
