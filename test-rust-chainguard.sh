#!/bin/bash

# Test script for Chainguard Rust image
set -e

echo "=== Testing Chainguard Rust Image ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "info")
            echo -e "${YELLOW}ℹ️  $message${NC}"
            ;;
    esac
}

# Container and image details
CONTAINER_NAME="test-rust-chainguard"
IMAGE_NAME="chainguard/rust:latest"

# Cleanup function
cleanup() {
    print_status "info" "Cleaning up..."
    container stop "$CONTAINER_NAME" 2>/dev/null || true
    container delete "$CONTAINER_NAME" 2>/dev/null || true
    rm -f hello_world.rs Cargo.toml hello_world hello_optimized
    rm -rf src/
}

# Set up trap to cleanup on exit
trap cleanup EXIT

echo ""
print_status "info" "1. Verifying Chainguard Rust image..."
if container images list | grep -q "chainguard/rust"; then
    print_status "success" "Found Chainguard Rust image"
else
    print_status "error" "Chainguard Rust image not found"
    exit 1
fi

echo ""
print_status "info" "2. Creating simple Rust test program..."

# Create a simple Rust program
cat > hello_world.rs << 'EOF'
fn main() {
    println!("Hello from Chainguard Rust! 🦀");
    
    // Test basic Rust functionality
    let numbers = vec![1, 2, 3, 4, 5];
    let sum: i32 = numbers.iter().sum();
    println!("Sum of {:?} = {}", numbers, sum);
    
    // Test string operations
    let message = "Rust is awesome!";
    println!("Message: {}", message);
    println!("Length: {}", message.len());
    
    // Test struct and methods
    struct Calculator {
        value: f64,
    }
    
    impl Calculator {
        fn new(value: f64) -> Calculator {
            Calculator { value }
        }
        
        fn add(&mut self, x: f64) {
            self.value += x;
        }
        
        fn multiply(&mut self, x: f64) {
            self.value *= x;
        }
        
        fn get_value(&self) -> f64 {
            self.value
        }
    }
    
    let mut calc = Calculator::new(10.0);
    calc.add(5.0);
    calc.multiply(2.0);
    println!("Calculator result: {}", calc.get_value());
    
    // Test pattern matching
    let number = 42;
    match number {
        0 => println!("Zero"),
        1..=10 => println!("Small number"),
        11..=100 => println!("Medium number: {}", number),
        _ => println!("Large number"),
    }
    
    println!("Rust test completed successfully! ✨");
}
EOF

print_status "success" "Created Rust test program"

echo ""
print_status "info" "3. Testing Rust version in container..."
if container run --name "$CONTAINER_NAME" --rm \
    --entrypoint sh \
    "$IMAGE_NAME" -c "rustc --version"; then
    print_status "success" "Rust version check successful"
else
    print_status "error" "Failed to get Rust version"
    exit 1
fi

echo ""
print_status "info" "4. Compiling Rust program..."
if container run --name "$CONTAINER_NAME" --rm \
    --volume "$(pwd):/workspace" \
    --workdir /workspace \
    --entrypoint sh \
    "$IMAGE_NAME" -c "rustc hello_world.rs -o hello_world"; then
    print_status "success" "Rust compilation successful"
else
    print_status "error" "Rust compilation failed"
    exit 1
fi

echo ""
print_status "info" "5. Running compiled Rust program..."
if container run --name "$CONTAINER_NAME" --rm \
    --volume "$(pwd):/workspace" \
    --workdir /workspace \
    --entrypoint sh \
    "$IMAGE_NAME" -c "./hello_world"; then
    print_status "success" "Rust program execution successful"
else
    print_status "error" "Failed to run Rust program"
    exit 1
fi

echo ""
print_status "info" "6. Testing Cargo (Rust package manager)..."

# Create a simple Cargo project
cat > Cargo.toml << 'EOF'
[package]
name = "chainguard_rust_test"
version = "0.1.0"
edition = "2021"

[dependencies]
EOF

# Move the Rust file to src/main.rs structure
mkdir -p src
mv hello_world.rs src/main.rs

if container run --name "$CONTAINER_NAME" --rm \
    --volume "$(pwd):/workspace" \
    --workdir /workspace \
    --entrypoint sh \
    "$IMAGE_NAME" -c "cargo --version"; then
    print_status "success" "Cargo version check successful"
else
    print_status "warning" "Cargo not available (expected for minimal Rust image)"
fi

echo ""
print_status "info" "7. Testing Rust compiler features..."

# Test if we can compile with optimizations
if container run --name "$CONTAINER_NAME" --rm \
    --volume "$(pwd):/workspace" \
    --workdir /workspace \
    --entrypoint sh \
    "$IMAGE_NAME" -c "rustc src/main.rs -O -o hello_optimized"; then
    print_status "success" "Optimized compilation successful"
    
    # Run the optimized version
    if container run --name "$CONTAINER_NAME" --rm \
        --volume "$(pwd):/workspace" \
        --workdir /workspace \
        --entrypoint sh \
        "$IMAGE_NAME" -c "./hello_optimized"; then
        print_status "success" "Optimized program execution successful"
    fi
else
    print_status "error" "Optimized compilation failed"
fi

echo ""
print_status "info" "8. Container information:"
container run --name "$CONTAINER_NAME" --rm \
    --entrypoint sh \
    "$IMAGE_NAME" -c "uname -a"

echo ""
print_status "info" "9. Checking Rust installation details..."
container run --name "$CONTAINER_NAME" --rm \
    --entrypoint sh \
    "$IMAGE_NAME" -c "rustc --version && echo 'Target:' && rustc --print target-list | head -5"

echo ""
print_status "success" "=== Rust test completed successfully! ==="
print_status "info" "Test files will be automatically cleaned up" 