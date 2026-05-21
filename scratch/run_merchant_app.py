import os
import subprocess
import sys

def main():
    target_dir = '/Users/venkata.rao/Documents/Dev/Dev_2026/tou-mob-acq/merchant_app'
    print(f"Changing directory to: {target_dir}")
    os.chdir(target_dir)
    
    print("Running: flutter run -d emulator-5554")
    try:
        # Run flutter run and pipe input/output/error directly to this process
        subprocess.run(['flutter', 'run', '-d', 'emulator-5554'], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running flutter run: {e}")
        sys.exit(e.returncode)

if __name__ == '__main__':
    main()
