#!/usr/bin/env bash
# test-linux.sh - Linux dotfiles test environment management
#
# Provides commands to build, run, and test dotfiles in an Ubuntu container.
# Supports both OrbStack (faster) and Docker runtimes.
#
# Usage: ./scripts/test-linux.sh <command>
#
# Commands:
#   build   Build the test Docker image
#   start   Start interactive test container
#   shell   Enter running container
#   test    Run automated installation test
#   clean   Remove container and image
#   help    Show help
#
set -euo pipefail

# Configuration
CONTAINER_NAME="dotfiles-test"
IMAGE_NAME="dotfiles-test:latest"

# Determine script and repository directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
DOCKERFILE_PATH="$DOTFILES_DIR/.docker/Dockerfile.dotfiles-test"

# Detect container runtime (OrbStack or Docker)
detect_runtime() {
    if command -v orb &>/dev/null && orb info &>/dev/null 2>&1; then
        RUNTIME="orbstack"
        echo "Using OrbStack runtime (faster startup)"
    elif command -v docker &>/dev/null; then
        RUNTIME="docker"
        echo "Using Docker runtime"
    else
        echo "ERROR: Neither OrbStack nor Docker found"
        echo ""
        echo "Install OrbStack (recommended for Mac):"
        echo "  brew install --cask orbstack"
        echo ""
        echo "Or install Docker:"
        echo "  brew install --cask docker"
        exit 1
    fi
}

# Build the test image
cmd_build() {
    detect_runtime
    echo ""
    echo "Building test image from $DOCKERFILE_PATH..."
    docker build -t "$IMAGE_NAME" -f "$DOCKERFILE_PATH" "$DOTFILES_DIR/.docker"
    echo ""
    echo "Image built: $IMAGE_NAME"
}

# Start interactive container with dotfiles mounted
cmd_start() {
    detect_runtime
    echo ""
    echo "Starting $CONTAINER_NAME container..."
    echo "Dotfiles mounted at: /home/tester/.dotfiles (read-only)"
    echo ""
    echo "To install dotfiles, run:"
    echo "  cd ~/.dotfiles && ./install"
    echo ""

    docker run -it --rm \
        --name "$CONTAINER_NAME" \
        --hostname "linux-test" \
        -v "$DOTFILES_DIR:/home/tester/.dotfiles:ro" \
        -w /home/tester \
        "$IMAGE_NAME"
}

# Enter running container
cmd_shell() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "ERROR: Container '$CONTAINER_NAME' is not running"
        echo ""
        echo "Start it first with:"
        echo "  $0 start"
        exit 1
    fi

    echo "Entering $CONTAINER_NAME..."
    docker exec -it "$CONTAINER_NAME" zsh
}

# Run automated installation test
cmd_test() {
    detect_runtime
    echo ""
    echo "Running automated dotfiles installation test..."
    echo ""

    # Build image if it doesn't exist
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo "Image not found, building first..."
        cmd_build
        echo ""
    fi

    # Run test: install dotfiles and verify shell loads
    docker run --rm \
        --name "${CONTAINER_NAME}-test" \
        -v "$DOTFILES_DIR:/home/tester/.dotfiles:ro" \
        "$IMAGE_NAME" \
        bash -c '
            set -e
            echo "=== Copying dotfiles (required since mount is read-only) ==="
            cp -r ~/.dotfiles ~/dotfiles-test
            cd ~/dotfiles-test

            echo ""
            echo "=== Running install script ==="
            ./install || { echo "ERROR: Install script failed"; exit 1; }

            echo ""
            echo "=== Verifying shell loads ==="
            zsh -c "echo Shell loaded successfully"

            echo ""
            echo "=== TEST PASSED ==="
        '

    echo ""
    echo "Test completed successfully!"
}

# Clean up container and image
cmd_clean() {
    echo "Cleaning up test environment..."

    # Stop and remove container if running
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Stopping container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
    fi

    # Remove container if exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Removing container: $CONTAINER_NAME"
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
    fi

    # Remove test container if exists
    docker rm "${CONTAINER_NAME}-test" 2>/dev/null || true

    # Remove image if exists
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo "Removing image: $IMAGE_NAME"
        docker rmi "$IMAGE_NAME" 2>/dev/null || true
    fi

    echo ""
    echo "Cleaned up test environment"
}

# Show help
cmd_help() {
    cat <<EOF
Linux Dotfiles Test Environment

A tool for testing dotfiles configuration in an Ubuntu container before
applying changes to your live macOS system.

Usage: $0 <command>

Commands:
  build   Build the test Docker image
  start   Start interactive test container (mounts dotfiles)
  shell   Enter a running container
  test    Run automated installation test
  clean   Remove container and image
  help    Show this help

Examples:
  # First time setup
  $0 build        # Build the Ubuntu test image
  $0 start        # Start interactive session

  # Quick automated test
  $0 test         # Build (if needed) and run install test

  # Interactive testing workflow
  $0 start        # Start container with zsh shell
  # In container: cd ~/.dotfiles && ./install
  # In container: test your configurations
  # In container: exit

  # Cleanup
  $0 clean        # Remove container and image

Runtime:
  This script automatically detects and uses OrbStack (if available)
  or falls back to Docker. OrbStack provides faster startup times
  (~2 seconds vs ~5-10 seconds for Docker).

  Install OrbStack: brew install --cask orbstack

Notes:
  - Dotfiles are mounted read-only at /home/tester/.dotfiles
  - The 'test' command copies dotfiles to a writable location
  - Container user 'tester' has passwordless sudo access
  - Default shell is zsh

EOF
}

# Main command dispatch
main() {
    local cmd="${1:-help}"

    case "$cmd" in
        build)
            cmd_build
            ;;
        start)
            cmd_start
            ;;
        shell)
            cmd_shell
            ;;
        test)
            cmd_test
            ;;
        clean)
            cmd_clean
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            echo "ERROR: Unknown command: $cmd"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
