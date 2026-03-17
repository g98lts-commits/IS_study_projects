# ClamAV Full System Scan Script
# Purpose: Perform a full system scan and send report

LOG_DIR="/var/log/clamav"
LOG_FILE="$LOG_DIR/full_scan_$(date +%Y%m%d).log"
REPORT_FILE="$LOG_DIR/report_$(date +%Y%m%d).txt"
SCAN_TARGETS="/ /home /var /opt"  # Target directories for scanning
MAX_SCAN_TIME="3600"  # Max scan time in seconds (1 hour)

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Starting full system scan"

# Perform the scan with timeout
timeout $MAX_SCAN_TIME clamscan \
  --recursive \
  --infected \
  --exclude-dir="^/sys" \
  --exclude-dir="^/proc" \
  --exclude-dir="^/dev" \
  --log="$LOG_FILE" \
  --move="$LOG_DIR/infected" \
  $SCAN_TARGETS

SCAN_EXIT_CODE=$?

# Generate report
echo "=== ClamAV Full Scan Report ===" > "$REPORT_FILE"
echo "Scan Date: $(date)" >> "$REPORT_FILE"
echo "Target Directories: $SCAN_TARGETS" >> "$REPORT_FILE"

if [ $SCAN_EXIT_CODE -eq 0 ]; then
  echo "Status: No infections found" >> "$REPORT_FILE"
  log_message "Scan completed successfully - no infections found"
elif [ $SCAN_EXIT_CODE -eq 1 ]; then
  echo "Status: Infections found and moved to quarantine" >> "$REPORT_FILE"
  log_message "Scan completed with infections - files moved to quarantine"
elif [ $SCAN_EXIT_CODE -eq 2 ]; then
  echo "Status: Some errors occurred during scan" >> "$REPORT_FILE"
  log_message "Scan completed with errors"
else
  echo "Status: Scan failed or timed out" >> "$REPORT_FILE"
  log_message "Scan failed or timed out (exit code: $SCAN_EXIT_CODE)"
fi

echo "Log file: $LOG_FILE" >> "$REPORT_FILE"

# Send report via email if mailutils is installed
if command -v mail &> /dev/null; then
  mail -s "ClamAV Scan Report - $(hostname)" admin@company.com < "$REPORT_FILE"
fi

log_message "Full scan completed. Exit code: $SCAN_EXIT_CODE"
