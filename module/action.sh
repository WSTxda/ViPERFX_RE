#!/system/bin/sh

# ViPER4Android FX Redesign variables
APP_PACKAGE="com.wstxda.viper4android"
APP_ACTIVITY="com.wstxda.viper4android.MainActivity"
DOWNLOAD_URL="https://github.com/WSTxda/ViperFX-RE-Releases/releases/latest"

# Action button messages
log_message() {
    echo "[INFO] $1"
}
error_message() {
    echo "[ERROR] $1"
}

# Start ViPER4Android FX Redesign application
log_message "Opening application..."
if am start -n "$APP_PACKAGE/$APP_ACTIVITY" > /dev/null 2>&1; then
    log_message "ViperFX opened successfully!"
else
    error_message "Failed to open ViperFX. Activity not found."
    log_message "App not installed, download and install the latest version from GitHub repository:"
    echo "$DOWNLOAD_URL"
fi