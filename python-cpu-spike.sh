#!/bin/bash
# Update and install Python
sudo apt update -y
sudo apt install -y python3

# Create and save the Python script
cat <<EOF > /home/ubuntu/cpu_spike.py
#!/usr/bin/env python3
import time

def simulate_cpu_spike(duration=30, cpu_percent=80):
    print(f"Simulating CPU spike at {cpu_percent}%...")
    start_time = time.time()

    target_percent = cpu_percent / 100
    active_duration = duration * target_percent
    sleep_duration = duration - active_duration

    while time.time() - start_time < active_duration:
        for _ in range(1000):
            result = sum(i * i for i in range(1000))

    if sleep_duration > 0:
        time.sleep(sleep_duration)

    print("CPU spike simulation completed.")

if __name__ == '__main__':
    simulate_cpu_spike(duration=30, cpu_percent=80)
EOF

# Make the Python script executable
chmod +x /home/ubuntu/cpu_spike.py

# Run the Python script
python3 /home/ubuntu/cpu_spike.py
