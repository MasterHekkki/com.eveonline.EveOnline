#!/bin/sh
set -eua pipefail

# URLs and checksums for the EVE Online launcher package
EVE_ONLINE_LAUNCHER_URL="https://launcher.ccpgames.com/eve-online/release/win32/x64/eve-online-1.9.4-full.nupkg"
EVE_ONLINE_LAUNCHER_NAME="eve-online-1.9.4-full.nupkg"
EVE_ONLINE_LAUNCHER_SHA512="70cd86437d7de0566228b7a5b0a5abd2c6c83bd3c6cb7e8f09678dec75c2f3ed2ca3b323227947c81c127ac41a0b27a052157baec1f4feecca6885518c9417a0"

# Change to the XDG data directory
cd "$XDG_DATA_HOME"
# Source constants (sets up environment variables)
. /app/constants.sh

# URLs and names for the EVE Online setup executable
eve_online_setup_exe_url="https://launcher.ccpgames.com/eve-online/release/win32/x64/eve-online-latest+Setup.exe"
eve_online_installer_name="eve-online-setup.exe"

# Path to the installed EVE Online launcher executable
eve_launcher_exe_path="$WINEPREFIX/drive_c/users/steamuser/AppData/Local/eve-online/eve-online.exe"

# Install if the eve-online exe does not exist
if ! [ -f "$eve_launcher_exe_path" ]; then
  # Install dotnet8 using winetricks (required by the launcher)
  umu-run winetricks -q dotnet8
  # Download the EVE Online installer
  curl -o "$eve_online_installer_name" -L "$eve_online_setup_exe_url"
  # Run the installer with Wine (no privilege elevation)
  WINE_NO_PRIV_ELEVATION=1 umu-run "$eve_online_installer_name"
  # Remove the installer after installation
  rm "$eve_online_installer_name"
fi

# Workaround for bug in 1.10.0 launcher. See: https://github.com/ValveSoftware/Proton/issues/1223
if ! [ -d "$WINEPREFIX/drive_c/users/$USER/AppData/Local/eve-online/app-1.9.4" ]; then
  # Download the specific launcher version
  EVE_ONLINE_LAUNCHER_URL="https://launcher.ccpgames.com/eve-online/release/win32/x64/eve-online-1.9.4-full.nupkg"
  EVE_ONLINE_LAUNCHER_NAME="eve-online-1.9.4-full.nupkg"
  EVE_ONLINE_LAUNCHER_SHA512="70cd86437d7de0566228b7a5b0a5abd2c6c83bd3c6cb7e8f09678dec75c2f3ed2ca3b323227947c81c127ac41a0b27a052157baec1f4feecca6885518c9417a0"

  wget "$EVE_ONLINE_LAUNCHER_URL" -O "$EVE_ONLINE_LAUNCHER_NAME"

  # Verify the SHA512 checksum of the downloaded file
  echo "$EVE_ONLINE_LAUNCHER_SHA512  $EVE_ONLINE_LAUNCHER_NAME" | sha512sum -c -
  # Unzip the launcher package
  unzip "$EVE_ONLINE_LAUNCHER_NAME" -d out/
  # Backup the buggy app-1.10.0 directory 
  mv "$WINEPREFIX/drive_c/users/$USER/AppData/Local/eve-online/app-1.10.0" "$WINEPREFIX/drive_c/users/$USER/AppData/Local/eve-online/app-1.10.0.bk" || true
  # Move the working version into place
  mv out/lib/net45 "$WINEPREFIX/drive_c/users/$USER/AppData/Local/eve-online/app-1.9.4"
  # Remove the backup directory
  rm -rf app-1.10.0.bk

  # Cleanup extracted files
  rm -rf out/
  # Launch the game with the fixed version and exit
  umu-run "$WINEPREFIX/drive_c/users/$USER/AppData/Local/eve-online/app-1.9.4/eve-online.exe"
  exit 0
fi

# If everything is installed, run the game
echo "Game installation detected. Running now..."
umu-run "$WINEPREFIX/drive_c/users/$USER/AppData/Local/eve-online/app-1.9.4/eve-online.exe"
