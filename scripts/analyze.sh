#!/usr/bin/env bash

# Exit immediately on error, treat unset variables as errors, and catch pipe failures
set -euo pipefail

# ANSI Color Codes for terminal output
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
COLOR_CYAN="\033[36m"
COLOR_BOLD="\033[1m"

# Function: Print usage information
print_help() {
    echo "Usage: $0 <log_file> [options]"
    echo "Options:"
    echo "  -f, --format <text|csv>   Output format (default: text)"
    echo "  -o, --output <path>       Output file path (default: stdout)"
    echo "  -c, --compare <old_log>   Compare with an older log to detect regressions"
    echo "  -v, --verbose             Enable verbose output (prints individual test times)"
    echo "  -h, --help                Print usage information"
}

# Initialize variables
FORMAT="text"
OUTPUT_FILE=""
COMPARE_LOG=""
VERBOSE=0

# Parse arguments using getopt
PARSED_ARGS=$(getopt -o f:o:c:vh --long format:,output:,compare:,verbose,help -n "$0" -- "$@")
eval set -- "$PARSED_ARGS"

while true; do
    case "$1" in
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -c|--compare)
            COMPARE_LOG="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Error: Invalid option $1" >&2
            print_help
            exit 1
            ;;
    esac
done

# Remaining argument is the log file
LOG_FILE="${1:-}"

if [[ -z "$LOG_FILE" ]]; then
    echo "Error: Missing required log file argument." >&2
    print_help
    exit 1
fi

if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: Log file '$LOG_FILE' does not exist." >&2
    exit 1
fi

# Optional regression comparison function
check_regressions() {
    local current_log="$1"
    local old_log="$2"
    
    if [[ ! -f "$old_log" ]]; then
        echo "Error: Comparison log '$old_log' does not exist." >&2
        exit 1
    fi

    echo "=== Regression Analysis (Comparing with $(basename "$old_log")) ==="
    
    # Extract tests that passed in old log but failed in current log
    awk '
        NR==FNR {
            if ($0 ~ /TEST PASS:/) {
                for(i=1;i<=NF;i++) if ($i ~ /rv32i-/) old_pass[$i]=1;
            }
            next;
        }
        {
            if ($0 ~ /TEST FAIL:/) {
                for(i=1;i<=NF;i++) {
                    if ($i ~ /rv32i-/ && ($i in old_pass)) {
                        print "  [REGRESSION DETECTED] Test " $i " passed previously but failed now!";
                        regressions++;
                    }
                }
            }
        }
        END {
            if (regressions == 0) {
                print "  No regressions detected.";
            }
        }
    ' "$old_log" "$current_log"
    echo "================================================================"
}

# Core analysis function using awk
analyze_log() {
    local log="$1"
    
    awk -v verbose="$VERBOSE" -v format="$FORMAT" -v log_name="$log" -v date_str="$(date '+%Y-%m-%d %H:%M:%S')" \
        -v c_green="$COLOR_GREEN" -v c_red="$COLOR_RED" -v c_yellow="$COLOR_YELLOW" -v c_reset="$COLOR_RESET" -v c_bold="$COLOR_BOLD" '
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
        t_name = $5;

        if ($0 ~ /TEST PASS:/) {
            pass_count++;
        } else if ($0 ~ /TEST FAIL:/) {
            fail_count++;
            failing_tests[fail_count] = t_name;
        } else if ($0 ~ /TEST SKIP:/) {
            skip_count++;
        }

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
            if (min_time == -1 || t_val < min_time) {
                min_time = t_val;
                min_name = t_name;
            }
            if (t_val > max_time) {
                max_time = t_val;
                max_name = t_name;
            }
            
            if (verbose) {
                print "  [VERBOSE] Test: " t_name " | Time: " t_val "s";
            }
        }
    }
    END {
        pass_rate = (total_tests > 0) ? (pass_count / total_tests) * 100 : 0;
        fail_rate = (total_tests > 0) ? (fail_count / total_tests) * 100 : 0;
        skip_rate = (total_tests > 0) ? (skip_count / total_tests) * 100 : 0;
        avg_time = (total_tests > 0) ? (sum_time / total_tests) : 0;
        verdict = (fail_count == 0) ? "PASS" : "FAIL";

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
            print "Verdict," verdict;
        } else {
            print "=== RISC-V Simulation Log Analysis ===";
            print "Log file: " log_name;
            print "Analysis date: " date_str;
            print "--- Results Summary ---";
            print "Total tests: " total_tests;
            print "Passed: " pass_count " (" sprintf("%.1f%%", pass_rate) ")";
            print "Failed: " fail_count " (" sprintf("%.1f%%", fail_rate) ")";
            print "Skipped: " skip_count " (" sprintf("%.1f%%", skip_rate) ")";
            
            if (fail_count > 0) {
                print "--- Failed Tests ---";
                for (i = 1; i <= fail_count; i++) {
                    print i ". " failing_tests[i];
                }
            }
            
            print "--- Timing Statistics ---";
            print "Min time: " (min_time == -1 ? 0 : min_time) "s (" min_name ")";
            print "Max time: " max_time "s (" max_name ")";
            print "Avg time: " sprintf("%.2f", avg_time) "s";
            
            if (verdict == "PASS") {
                print "--- Verdict: " c_green c_bold "PASS" c_reset " ---";
            } else {
                print "--- Verdict: " c_red c_bold "FAIL" c_reset " ---";
            }
            print "Exit code: " (fail_count == 0 ? 0 : 1);
            print "======================================";
        }
    }
    ' "$log"
}

# Run regression check if requested
if [[ -n "$COMPARE_LOG" ]]; then
    check_regressions "$LOG_FILE" "$COMPARE_LOG"
fi

# Execute analysis and handle output destination
if [[ -n "$OUTPUT_FILE" ]]; then
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    analyze_log "$LOG_FILE" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" > "$OUTPUT_FILE"
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
