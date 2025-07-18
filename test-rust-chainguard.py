#!/usr/bin/env python3

import sys
import time
import subprocess
import os
import shutil

def run_command(cmd, check=True):
    """Run a command and return the result"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=check)
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except subprocess.CalledProcessError as e:
        return e.stdout.strip(), e.stderr.strip(), e.returncode

def cleanup_files():
    """Clean up test files"""
    files_to_remove = ['hello_world.rs', 'Cargo.toml', 'hello_world', 'hello_optimized']
    for file in files_to_remove:
        if os.path.exists(file):
            os.remove(file)
    if os.path.exists('src'):
        shutil.rmtree('src')

def test_rust_chainguard():
    """Test the Chainguard Rust image"""
    print("=== Testing Chainguard Rust Image ===")
    
    try:
        # Step 1: Verify Rust image exists
        print("\n1. Verifying Chainguard Rust image...")
        stdout, stderr, code = run_command("container images list | grep chainguard/rust")
        if code == 0:
            print("✅ Found Chainguard Rust image")
        else:
            print("❌ Chainguard Rust image not found")
            return False
        
        # Step 2: Create Rust test program
        print("\n2. Creating simple Rust test program...")
        rust_code = '''fn main() {
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
}'''
        
        with open('hello_world.rs', 'w') as f:
            f.write(rust_code)
        print("✅ Created Rust test program")
        
        # Step 3: Test Rust version
        print("\n3. Testing Rust version in container...")
        cmd = 'container run --name test-rust-chainguard --rm --entrypoint sh chainguard/rust:latest -c "rustc --version"'
        stdout, stderr, code = run_command(cmd)
        if code == 0:
            print("✅ Rust version check successful")
            print(f"Rust version: {stdout}")
        else:
            print(f"❌ Failed to get Rust version: {stderr}")
            return False
        
        # Step 4: Compile Rust program
        print("\n4. Compiling Rust program...")
        cwd = os.getcwd()
        cmd = f'container run --name test-rust-chainguard --rm --volume "{cwd}:/workspace" --workdir /workspace --entrypoint sh chainguard/rust:latest -c "rustc hello_world.rs -o hello_world"'
        stdout, stderr, code = run_command(cmd)
        if code == 0:
            print("✅ Rust compilation successful")
        else:
            print(f"❌ Rust compilation failed: {stderr}")
            return False
        
        # Step 5: Run compiled program
        print("\n5. Running compiled Rust program...")
        cmd = f'container run --name test-rust-chainguard --rm --volume "{cwd}:/workspace" --workdir /workspace --entrypoint sh chainguard/rust:latest -c "./hello_world"'
        stdout, stderr, code = run_command(cmd)
        if code == 0:
            print("✅ Rust program execution successful")
            print(f"Program output:\n{stdout}")
        else:
            print(f"❌ Failed to run Rust program: {stderr}")
            return False
        
        # Step 6: Test Cargo
        print("\n6. Testing Cargo (Rust package manager)...")
        cmd = f'container run --name test-rust-chainguard --rm --entrypoint sh chainguard/rust:latest -c "cargo --version"'
        stdout, stderr, code = run_command(cmd)
        if code == 0:
            print("✅ Cargo version check successful")
            print(f"Cargo version: {stdout}")
        else:
            print("⚠️  Cargo not available (expected for minimal Rust image)")
        
        # Step 7: Test optimized compilation
        print("\n7. Testing Rust compiler features...")
        
        # Create Cargo project structure
        os.makedirs('src', exist_ok=True)
        shutil.move('hello_world.rs', 'src/main.rs')
        
        cargo_toml = '''[package]
name = "chainguard_rust_test"
version = "0.1.0"
edition = "2021"

[dependencies]'''
        
        with open('Cargo.toml', 'w') as f:
            f.write(cargo_toml)
        
        cmd = f'container run --name test-rust-chainguard --rm --volume "{cwd}:/workspace" --workdir /workspace --entrypoint sh chainguard/rust:latest -c "rustc src/main.rs -O -o hello_optimized"'
        stdout, stderr, code = run_command(cmd)
        if code == 0:
            print("✅ Optimized compilation successful")
            
            # Run optimized version
            cmd = f'container run --name test-rust-chainguard --rm --volume "{cwd}:/workspace" --workdir /workspace --entrypoint sh chainguard/rust:latest -c "./hello_optimized"'
            stdout, stderr, code = run_command(cmd)
            if code == 0:
                print("✅ Optimized program execution successful")
                print(f"Optimized output:\n{stdout}")
        else:
            print(f"❌ Optimized compilation failed: {stderr}")
        
        # Step 8: Container information
        print("\n8. Container information:")
        cmd = 'container run --name test-rust-chainguard --rm --entrypoint sh chainguard/rust:latest -c "uname -a"'
        stdout, stderr, code = run_command(cmd)
        if code == 0:
            print(f"System info: {stdout}")
        
        # Step 9: Rust installation details
        print("\n9. Checking Rust installation details...")
        cmd = 'container run --name test-rust-chainguard --rm --entrypoint sh chainguard/rust:latest -c "rustc --version && echo \'Targets:\' && rustc --print target-list | head -5"'
        stdout, stderr, code = run_command(cmd)
        if code == 0:
            print(f"Rust details:\n{stdout}")
        
        print("\n=== Test completed successfully! ===")
        return True
        
    except Exception as e:
        print(f"❌ Test failed with exception: {e}")
        return False
    finally:
        print("\n🧹 Cleaning up test files...")
        cleanup_files()

if __name__ == "__main__":
    success = test_rust_chainguard()
    sys.exit(0 if success else 1) 