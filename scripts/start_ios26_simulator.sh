#!/usr/bin/env bash
set -euo pipefail

# Script to create and boot an iOS 26.x simulator and open the Simulator app.
# Usage: ./scripts/start_ios26_simulator.sh

runtime=$(xcrun simctl list runtimes | grep -Eo 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9]+(-[0-9]+)?' | grep 'iOS-26' | head -n1 || true)
if [ -z "$runtime" ]; then
  echo "iOS 26 runtime not found. Install via Xcode -> Settings -> Components and retry."
  exit 2
fi

# Prefer iPhone 16 Pro if available
devtype=$(xcrun simctl list devicetypes | awk -F'[()]' '/iPhone 16 Pro/ {print $2; exit}')
if [ -z "$devtype" ]; then
  # fallback: pick the first iPhone device type
  devtype=$(xcrun simctl list devicetypes | awk -F'[()]' '/iPhone/ {print $2; exit}')
fi

name="iPhone-16-Pro-iOS26.2"

# Check if simulator already exists
udid=$(xcrun simctl list devices | grep -F "$name" | sed -n 's/.*(\(.*\)).*/\1/p' | head -n1 || true)
if [ -n "$udid" ]; then
  echo "Found existing simulator: $name ($udid)"
else
  echo "Creating simulator $name using devtype=$devtype runtime=$runtime"
  udid=$(xcrun simctl create "$name" "$devtype" "$runtime")
  echo "Created simulator UDID: $udid"
fi

echo "Booting simulator $udid..."
xcrun simctl boot "$udid" || true
open -a Simulator || true

echo "Waiting for device to become Booted..."
for i in $(seq 1 60); do
  line=$(xcrun simctl list devices | grep "$udid" || true)
  if echo "$line" | grep -q "Booted"; then
    echo "Simulator is Booted"
    break
  fi
  sleep 1
done

echo "Simulator ready: $udid"
echo "Run 'flutter devices' to confirm and then 'flutter run -d $udid' to launch the app."
