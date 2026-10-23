#!/usr/bin/env bash
#
# sysstats.sh — Report CPU, RAM, and GPU usage/temperature as JSON
#
# Dependencies (optional, script degrades gracefully if missing):
#   - lm-sensors      (CPU temp via `sensors`)
#   - nvidia-smi      (NVIDIA GPU stats)
#   - intel_gpu_top   (Intel GPU utilization; from igt-gpu-tools)
#   - lspci           (nicer Intel GPU names; from pciutils)
#
# Usage: ./sysstats.sh

set -euo pipefail

STATE_FILE="${SYSSTATS_STATE_FILE:-/tmp/.sysstats_cpu_prev}"

# ---------- helpers ----------

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

null_or_num() {
    local v="$1"
    if [[ -n "$v" && "$v" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
        printf '%s' "$v"
    else
        printf 'null'
    fi
}

# ---------- CPU usage (% since previous run) ----------

get_cpu_usage() {
    local user nice sys idle iowait irq softirq steal
    read -r _ user nice sys idle iowait irq softirq steal _ < /proc/stat

    local idle_total total
    idle_total=$((idle + iowait))
    total=$((user + nice + sys + idle_total + irq + softirq + steal))

    if [[ -r "$STATE_FILE" ]]; then
        local ptotal pidle
        read -r ptotal pidle < "$STATE_FILE" 2>/dev/null || { ptotal=""; pidle=""; }

        if [[ -n "$ptotal" && -n "$pidle" ]]; then
            local totald idled
            totald=$((total - ptotal))
            idled=$((idle_total - pidle))

            if [[ "$totald" -gt 0 ]]; then
                awk -v totald="$totald" -v idled="$idled" \
                    'BEGIN { printf "%.1f", (totald - idled) / totald * 100 }'
            else
                echo ""
            fi
        else
            echo ""
        fi
    else
        echo ""
    fi

    echo "$total $idle_total" > "$STATE_FILE"
}

get_cpu_temp() {
    if command -v sensors >/dev/null 2>&1; then
        local temp
        temp=$(sensors -A -u 2>/dev/null \
            | awk '/^Package id 0:|^Tdie:|^Tctl:|^temp1:/{found=1} found && /temp[0-9]*_input/{print $2; exit}')
        if [[ -n "$temp" ]]; then
            printf '%.1f' "$temp"
            return
        fi
    fi

    if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
        local raw
        raw=$(cat /sys/class/thermal/thermal_zone0/temp)
        awk -v r="$raw" 'BEGIN { printf "%.1f", r/1000 }'
        return
    fi

    echo ""
}

# ---------- RAM usage ----------

get_ram_stats() {
    local total used free_ percent
    read -r total used free_ <<<"$(free -m | awk '/^Mem:/{print $2, $3, $4}')"

    if [[ -z "$total" || "$total" -eq 0 ]]; then
        echo "0 0 0 0.0"
        return
    fi

    percent=$(awk -v u="$used" -v t="$total" 'BEGIN { printf "%.1f", (u/t)*100 }')
    echo "$total $used $free_ $percent"
}

# ---------- GPU: NVIDIA ----------
# Prints one JSON object per line.

get_nvidia_entries() {
    command -v nvidia-smi >/dev/null 2>&1 || return 0

    local raw
    raw=$(nvidia-smi --query-gpu=index,name,utilization.gpu,temperature.gpu,memory.used,memory.total \
        --format=csv,noheader,nounits 2>/dev/null || true)
    [[ -z "$raw" ]] && return 0

    local idx name util temp memused memtotal name_esc
    while IFS=',' read -r idx name util temp memused memtotal; do
        idx=$(echo "$idx" | xargs)
        name=$(echo "$name" | xargs)
        util=$(echo "$util" | xargs)
        temp=$(echo "$temp" | xargs)
        memused=$(echo "$memused" | xargs)
        memtotal=$(echo "$memtotal" | xargs)
        name_esc=$(json_escape "$name")

        printf '{"index":%s,"vendor":"nvidia","name":"%s","driver":"nvidia","usage":%s,"temp":%s,"freq_mhz":null,"memory_used_mb":%s,"memory_total_mb":%s}\n' \
            "$idx" "$name_esc" "$(null_or_num "$util")" "$(null_or_num "$temp")" \
            "$(null_or_num "$memused")" "$(null_or_num "$memtotal")"
    done <<< "$raw"
}

# ---------- GPU: Intel (i915 / xe) ----------
# Prints one JSON object per line. Arg 1: starting index.

intel_busy_pct() {
    # Max engine "busy" % from the last intel_gpu_top sample.
    # Needs root, CAP_PERFMON, or kernel.perf_event_paranoid <= 0.
    local cardname="$1"
    command -v intel_gpu_top >/dev/null 2>&1 || return 0

    timeout 5 intel_gpu_top -J -s 500 -n 2 -d "drm:/dev/dri/$cardname" 2>/dev/null \
        | awk '
            /"period"/ { max = ""; }          # new sample: reset
            /"busy"/   {
                v = $0
                sub(/.*"busy":[ ]*/, "", v)
                sub(/[^0-9.].*/, "", v)
                if (v != "" && (max == "" || v + 0 > max + 0)) max = v
            }
            END { if (max != "") printf "%.1f", max }
        ' || true
}

get_intel_entries() {
    local idx="$1"
    local card dev cardname vendor driver slot name usage temp freq hw f lspci_out

    for card in /sys/class/drm/card*; do
        [[ "$card" =~ /card[0-9]+$ ]] || continue
        dev="$card/device"
        [[ -r "$dev/vendor" ]] || continue
        vendor=$(<"$dev/vendor")
        [[ "$vendor" == "0x8086" ]] || continue

        cardname=$(basename "$card")
        driver=$(basename "$(readlink -f "$dev/driver" 2>/dev/null)" 2>/dev/null || true)
        [[ -z "$driver" ]] && driver="unknown"

        # Name
        name="Intel GPU"
        if command -v lspci >/dev/null 2>&1; then
            slot=$(basename "$(readlink -f "$dev")")
            lspci_out=$(lspci -s "$slot" -mm 2>/dev/null \
                | awk -F'"' '{print $4 " " $6}' || true)
            [[ -n "$lspci_out" ]] && name="$lspci_out"
        fi

        # Utilization
        usage=$(intel_busy_pct "$cardname")

        # Temperature (hwmon; discrete Arc exposes this, most iGPUs do not)
        temp=""
        for hw in "$dev"/hwmon/hwmon*; do
            [[ -d "$hw" ]] || continue
            for f in "$hw"/temp*_input; do
                [[ -r "$f" ]] || continue
                temp=$(awk '{ printf "%.1f", $1/1000 }' "$f" 2>/dev/null || true)
                [[ -n "$temp" ]] && break 2
            done
        done

        # Current frequency in MHz (i915 and xe locations)
        freq=""
        for f in "$card/gt_act_freq_mhz" \
                 "$card/gt_cur_freq_mhz" \
                 "$dev/tile0/gt0/freq0/cur_freq" \
                 "$dev/tile0/gt0/freq0/act_freq"; do
            if [[ -r "$f" ]]; then
                freq=$(cat "$f" 2>/dev/null || true)
                [[ -n "$freq" ]] && break
            fi
        done

        printf '{"index":%s,"vendor":"intel","name":"%s","driver":"%s","usage":%s,"temp":%s,"freq_mhz":%s,"memory_used_mb":null,"memory_total_mb":null}\n' \
            "$idx" "$(json_escape "$name")" "$(json_escape "$driver")" \
            "$(null_or_num "$usage")" "$(null_or_num "$temp")" "$(null_or_num "$freq")"
        idx=$((idx + 1))
    done
}

get_gpu_json() {
    local entries=()
    local line

    while IFS= read -r line; do
        [[ -n "$line" ]] && entries+=("$line")
    done < <(get_nvidia_entries)

    while IFS= read -r line; do
        [[ -n "$line" ]] && entries+=("$line")
    done < <(get_intel_entries "${#entries[@]}")

    if [[ ${#entries[@]} -eq 0 ]]; then
        echo "[]"
        return
    fi

    local joined
    joined=$(IFS=,; echo "${entries[*]}")
    echo "[$joined]"
}

# ---------- assemble JSON ----------

main() {
    local cpu_usage cpu_temp
    cpu_usage=$(get_cpu_usage)
    cpu_temp=$(get_cpu_temp)

    read -r ram_total ram_used ram_free ram_percent <<< "$(get_ram_stats)"

    local gpu_json
    gpu_json=$(get_gpu_json)

    cat <<EOF
{
  "cpu": {
    "usage": $(null_or_num "$cpu_usage"),
    "temp": $(null_or_num "$cpu_temp")
  },
  "ram": {
    "total_mb": $(null_or_num "$ram_total"),
    "used_mb": $(null_or_num "$ram_used"),
    "free_mb": $(null_or_num "$ram_free"),
    "usage": $(null_or_num "$ram_percent")
  },
  "gpu": $gpu_json
}
EOF
}

main "$@"