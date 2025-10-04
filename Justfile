# Justfile for common developer and CI/CD tasks

# Default configuration variables
set shell := ["/bin/zsh", "-cu"]

BUILD_CONFIGURATION := 'debug'
CODESIGN_ID := '-'
APP_ROOT := ''
SYFT := 'syft'
GRYPE := 'grype'

# Print help
@default:
	just --list

# Build (debug or release)
@build:
	BUILD_CONFIGURATION={{BUILD_CONFIGURATION}} make build

# Install into project root (no sudo)
@install:
	BUILD_CONFIGURATION={{BUILD_CONFIGURATION}} DESTDIR=`git rev-parse --show-toplevel`/ SUDO= make install

# Release build + package (signed if CODESIGN_ID provided)
@release:
	BUILD_CONFIGURATION=release CODESIGN_OPTS="--force --sign '{{CODESIGN_ID}}' --timestamp" make release

# Run unit tests (SBOM soft step included)
@test:
	BUILD_CONFIGURATION={{BUILD_CONFIGURATION}} make test

# Run CLI integration tests (requires running services)
@integration:
	BUILD_CONFIGURATION={{BUILD_CONFIGURATION}} APP_ROOT={{APP_ROOT}} make integration

# Start/Stop system services
@start:
	if [ -n "{{APP_ROOT}}" ]; then bin/container system start --app-root "{{APP_ROOT}}"; else bin/container system start; fi

@stop:
	bin/container system stop || true

# SBOM generation and vulnerability scan (soft fail if tools missing)
@sbom:
	BUILD_CONFIGURATION={{BUILD_CONFIGURATION}} make sbom-soft

# Direct SBOM E2E script
@sbom-e2e:
	BUILD_CONFIGURATION={{BUILD_CONFIGURATION}} scripts/sbom_e2e.sh

# Codesign local installed binaries with provided identity
@sign-local:
	@if [ "{{CODESIGN_ID}}" = "-" ]; then echo "Set CODESIGN_ID to your Developer ID"; exit 1; fi
	codesign --force --sign '{{CODESIGN_ID}}' --timestamp bin/container
	codesign --force --sign '{{CODESIGN_ID}}' --timestamp bin/container-apiserver
	find libexec/container/plugins -type f -perm +111 -maxdepth 3 -exec codesign --force --sign '{{CODESIGN_ID}}' --timestamp {} +

# Docs
@docs:
	make docs

# Clean
@clean:
	make clean

# Git operations
@git-status:
	@echo "→ git status"
	@git status

@git-pull:
	@echo "→ git pull --rebase"
	@git pull --rebase

@git-push:
	@echo "→ git push"
	@git push

@git-stash:
	@echo "→ git stash push -u -m \"Auto-stash $(date +'%Y-%m-%d %H:%M:%S')\""
	@git stash push -u -m "Auto-stash $(date +'%Y-%m-%d %H:%M:%S')"

@git-stash-pop:
	@echo "→ git stash pop"
	@git stash pop

@git-stash-list:
	@echo "→ git stash list"
	@git stash list

# Commit with message (usage: just git-commit "your message")
@git-commit message:
	@echo "→ git add -A"
	@git add -A
	@echo "→ git commit -m \"{{message}}\""
	@git commit -m "{{message}}"

# Safe sync: stash, pull, pop
@git-sync:
	@if ! git diff-index --quiet HEAD --; then \
		echo "Stashing local changes..."; \
		echo "→ git stash push -u -m \"Auto-stash before sync $(date +'%Y-%m-%d %H:%M:%S')\""; \
		git stash push -u -m "Auto-stash before sync $(date +'%Y-%m-%d %H:%M:%S')"; \
		echo "→ git pull --rebase"; \
		git pull --rebase && { echo "→ git stash pop"; git stash pop; }; \
	else \
		echo "→ git pull --rebase"; \
		git pull --rebase; \
	fi

# Show current branch
@git-branch:
	@echo "→ git branch --show-current"
	@git branch --show-current

# Create and checkout new branch (usage: just git-new-branch "branch-name")
@git-new-branch name:
	@echo "→ git checkout -b \"{{name}}\""
	@git checkout -b "{{name}}"

# Show recent commit log
@git-log:
	@echo "→ git log --oneline --decorate --graph -10"
	@git log --oneline --decorate --graph -10

# Show uncommitted changes
@git-diff:
	@echo "→ git diff HEAD"
	@git diff HEAD
