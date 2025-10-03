# Justfile for common developer and CI/CD tasks

# Default configuration variables
set shell := ["/bin/zsh", "-cu"]

BUILD_CONFIGURATION := env_var("BUILD_CONFIGURATION", "debug")
CODESIGN_ID := env_var("CODESIGN_ID", "-")
APP_ROOT := env_var("APP_ROOT", "")
SYFT := env_var("SYFT", "syft")
GRYPE := env_var("GRYPE", "grype")

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
	bin/container system start {{ if APP_ROOT != "" { print("--app-root " + APP_ROOT) } }}

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
