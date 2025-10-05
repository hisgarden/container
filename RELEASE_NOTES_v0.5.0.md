# Release v0.5.0: Enhanced Development Workflow

## 🚀 New Features

### Enhanced Justfile
- **Git Operations**: Added comprehensive git commands (status, pull, push, stash, commit, sync)
- **Docker Compatibility**: Added `just docker` alias for seamless Docker command compatibility
- **Command Transparency**: All commands now echo before execution for better debugging
- **Release Workflow**: Enhanced release process with git operations

### Git Commands Added
- `just git-status` - Show git status
- `just git-pull` - Pull with rebase
- `just git-push` - Push changes
- `just git-commit "message"` - Stage all and commit
- `just git-sync` - Safe sync (auto-stash if needed)
- `just git-new-branch "name"` - Create and checkout new branch
- `just git-log` - Show recent commits
- `just git-diff` - Show uncommitted changes

### Docker Compatibility
- `just docker` - Full Docker command compatibility
- Shell alias: `alias docker="just docker"`
- Transparent command mapping to container CLI

### Release Workflow
- `just release` - Build release with tests (temporarily disabled for Swift 6 migration)
- `just release-and-push` - Complete workflow: build → commit → push

## 🔧 Technical Improvements
- Swift 6 compatibility preparation
- Enhanced build system with proper signing
- Improved error handling and user feedback

## 📝 Usage Examples
```bash
# Git operations
just git-status
just git-commit "Add new feature"
just git-sync

# Docker compatibility  
just docker list
just docker run --help

# Release workflow
just release-and-push
```

## 🏗️ Build Information
- **Version**: v0.5.0
- **Commit**: facf3db
- **Build**: release
- **Platform**: macOS (arm64)

## 🔄 Migration Notes
- Tests temporarily disabled due to Swift 6 testing framework migration
- Docker alias provides seamless compatibility for existing Docker workflows
- Enhanced git operations improve development workflow efficiency
