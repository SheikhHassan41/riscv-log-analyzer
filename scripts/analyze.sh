#!/usr/bin/env bash

# Exit immediately on error, treat unset variables as errors, and catch pipe failures
set -euo pipefail

# Function: Print usage information
print_help() {
    echo "Usage: $0 <log_file> [options]"
    echo "Options:"
    echo "  --format [text|csv]   Output format (default: text)"
    echo "  --output <path>       Output file path (default: stdout)"
    echo "  --verbose             Enable verbose output (prints individual test times)"
    echo "  --help                Print usage information"
}

# Initialize variables
LOG_FILE=""
FORMAT="text"
OUTPUT_FILE=""
VERBOSE=0

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=1
            shift
            ;;
        --help)
            print_help
            exit 0
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            print_help
            exit 1
            ;;
        *)
            if [[ -z "$LOG_FILE" ]]; then
                LOG_FILE="$1"
            else
                echo "Error: Unexpected argument $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate that a log file was provided
if [[ -z "$LOG_FILE" ]]; then
    echo "Error: Missing required log file argument." >&2
    print_help
    exit 1
fi

# Validate that the log file exists
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: Log file '$LOG_FILE' does not exist." >&2
    exit 1
fi

# Function: Analyze log file and generate formatted statistics
analyze_log() {
    local log="$1"
    
    awk -v verbose="$VERBOSE" -v format="$FORMAT" '
    BEGIN {
        total_tests = 0;
        pass_count = 0;
        fail_count = 0;
        skip_count = 0;
        min_time = -1;
        max_time = 0;
        sum_time = 0;
    }
    /TEST PASS:|TEST FAIL:|TEST SKIP:/ {
        total_tests++;
        t_name = $5; # Field 5 is the test name (e.g., rv32i-add)

        if ($0 ~ /TEST PASS:/) {
            pass_count++;
        } else if ($0 ~ /TEST FAIL:/) {
            fail_count++;
            failing_tests[fail_count] = t_name;
        } else if ($0 ~ /TEST SKIP:/) {
            skip_count++;
        }

        # Extract execution time string in format (X.XXs)
        time_str = "";
        for (i = 1; i <= NF; i++) {
            if ($i ~ /\([0-9.]+s\)/) {
                time_str = $i;
            }
        }
        if (time_str != "") {
            gsub(/\(|\)s/, "", time_str);
            t_val = time_str + 0;
            sum_time += t_val;
            if (min_time == -1 || t_val < min_time) min_time = t_val;
            if (t_val > max_time) max_time = t_val;
            
            if (verbose) {
                print "  [VERBOSE] Test: " t_name " | Time: " t_val "s";
            }
        }
    }
    END {
        pass_rate = (total_tests > 0) ? (pass_count / total_tests) * 100 : 0;
        avg_time = (total_tests > 0) ? (sum_time / total_tests) : 0;

        if (format == "csv") {
            print "Metric,Value";
            print "TotalTests," total_tests;
            print "Passed," pass_count;
            print "Failed," fail_count;
            print "Skipped," skip_count;
            print "PassRate(%)," sprintf("%.2f", pass_rate);
            print "MinTime(s)," (min_time == -1 ? 0 : min_time);
            print "MaxTime(s)," max_time;
            print "AvgTime(s)," sprintf("%.2f", avg_time);
        } else {
            print "=== RISC-V Log Analysis Summary ===";
            print "Total Tests Run : " total_tests;
            print "Passed          : " pass_count;
            print "Failed          : " fail_count;
            print "Skipped         : " skip_count;
            print sprintf("Pass Rate       : %.2f%%", pass_rate);
            print "--- Execution Time Statistics ---";
            print sprintf("Min Time        : %.2fs", (min_time == -1 ? 0 : min_time));
            print sprintf("Max Time        : %.2fs", max_time);
            print sprintf("Avg Time        : %.2fs", avg_time);
            
            if (fail_count > 0) {
                print "--- Failing Tests ---";
                for (i = 1; i <= fail_count; i++) {
                    print "  - " failing_tests[i];
                }
            }
            print "===================================";
        }
    }
    ' "$log"
}

# Execute analysis and handle output destination
if [[ -n "$OUTPUT_FILE" ]]; then
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    analyze_log "$LOG_FILE" > "$OUTPUT_FILE"
else
    analyze_log "$LOG_FILE"
fi

# Determine exit code: 0 if no tests failed, 1 if any failed
FAIL_COUNT=$(grep -c "TEST FAIL:" "$LOG_FILE" || true)
if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
else
    exit 0
fi
