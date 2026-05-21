import os
import subprocess
import time
import sys

def run_cmd(cmd, check=True):
    print(f"Running command: {cmd}")
    return subprocess.run(cmd, shell=True, text=True, capture_output=True, check=check)

def kill_emulator():
    print("Finding running emulator processes...")
    try:
        # Find PIDs of qemu-system-aarch64 or emulator
        res = run_cmd("pgrep -f 'emulator|qemu-system'", check=False)
        pids = res.stdout.strip().split('\n')
        pids = [p for p in pids if p]
        if pids:
            print(f"Killing emulator processes: {pids}")
            for pid in pids:
                run_cmd(f"kill -9 {pid}", check=False)
            time.sleep(2)
        else:
            print("No emulator processes running.")
    except Exception as e:
        print(f"Error killing emulator: {e}")

def start_emulator():
    emulator_path = "/Users/venkata.rao/Library/Android/sdk/emulator/emulator"
    cmd = f"{emulator_path} @Pixel_7 -dns-server 8.8.8.8,1.1.1.1 -no-snapshot-load"
    print(f"Starting emulator with command: {cmd}")
    # Start in background
    subprocess.Popen(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("Emulator started in background.")

def wait_for_boot():
    print("Waiting for device to connect to adb...")
    start_time = time.time()
    while time.time() - start_time < 90:
        res = run_cmd("adb devices", check=False)
        if "emulator-5554" in res.stdout:
            print("Device emulator-5554 found in adb devices list.")
            break
        time.sleep(2)
    else:
        print("Timeout waiting for emulator-5554 in adb devices.")
        sys.exit(1)

    print("Waiting for boot to complete...")
    start_time = time.time()
    while time.time() - start_time < 90:
        res = run_cmd("adb shell getprop sys.boot_completed", check=False)
        if res.stdout.strip() == "1":
            print("Emulator booted successfully!")
            break
        time.sleep(2)
    else:
        print("Timeout waiting for boot_completed.")
        sys.exit(1)

def main():
    kill_emulator()
    start_emulator()
    wait_for_boot()
    print("Setting private DNS mode to off just in case...")
    run_cmd("adb shell settings put global private_dns_mode off", check=False)
    print("Done!")

if __name__ == '__main__':
    main()
