#!/usr/bin/env bash
#
# sysstats.sh — Report CPU, RAM, and GPU usage/temperature as JSON
#
# Dependencies (optional, script degrades gracefully if missing):
#   - lm-sensors (for CPU temp via `sensors`)
#   - nvidia-smi (for NVIDIA GPU stats)
#   - bc (for floating point math) — falls back to awk if missing
#
# Usage: ./sysstats.sh

set -euo pipefail


STATE_FILE="${SYSSTATS_STATE_FILE:-/tmp/.sysstats_cpu_prev}"

# ---------- helpers ----------

json_escape() {
    # Minimal JSON string escaping
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

null_or_num() {
    # Print value if non-empty numeric, else "null"
    local v="$1"
    if [[ -n "$v" && "$v" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
        printf '%s' "$v"
    else
        printf 'null'
    fi
}

# ---------- CPU usage (% over a short sample window) ----------

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

    # save current snapshot for next run
    echo "$total $idle_total" > "$STATE_FILE"
}

get_cpu_temp() {
    # Try lm-sensors first
    if command -v sensors >/dev/null 2>&1; then
        local temp
        temp=$(sensors -A -u 2>/dev/null \
            | awk '/^Package id 0:|^Tdie:|^Tctl:|^temp1:/{found=1} found && /temp[0-9]*_input/{print $2; exit}')
        if [[ -n "$temp" ]]; then
            printf '%.1f' "$temp"
            return
        fi
    fi

    # Fallback: thermal zone (common on Linux, esp. laptops/ARM)
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
    # Outputs: total_mb used_mb free_mb percent
    local total used free_ percent
    read -r total used free_ <<<"$(free -m | awk '/^Mem:/{print $2, $3, $4}')"

    if [[ -z "$total" || "$total" -eq 0 ]]; then
        echo "0 0 0 0.0"
        return
    fi

    percent=$(awk -v u="$used" -v t="$total" 'BEGIN { printf "%.1f", (u/t)*100 }')
    echo "$total $used $free_ $percent"
}

# ---------- GPU usage/temp (NVIDIA) ----------

get_gpu_json() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        local raw
        raw=$(nvidia-smi --query-gpu=index,name,utilization.gpu,temperature.gpu,memory.used,memory.total \
            --format=csv,noheader,nounits 2>/dev/null || true)

        if [[ -z "$raw" ]]; then
            echo "[]"
            return
        fi

        local entries=()
        while IFS=',' read -r idx name util temp memused memtotal; do
            idx=$(echo "$idx" | xargs)
            name=$(echo "$name" | xargs)
            util=$(echo "$util" | xargs)
            temp=$(echo "$temp" | xargs)
            memused=$(echo "$memused" | xargs)
            memtotal=$(echo "$memtotal" | xargs)
            name_esc=$(json_escape "$name")

            entries+=("{\"index\":$idx,\"name\":\"$name_esc\",\"usage\":$(null_or_num "$util"),\"temp\":$(null_or_num "$temp"),\"memory_used_mb\":$(null_or_num "$memused"),\"memory_total_mb\":$(null_or_num "$memtotal")}")
        done <<< "$raw"

        local joined
        joined=$(IFS=,; echo "${entries[*]}")
        echo "[$joined]"
    else
        # No NVIDIA tooling found (could add amdgpu/rocm-smi or intel_gpu_top support here)
        echo "[]"
    fi
}

# ---------- assemble JSON ----------

main() {
    local cpu_usage cpu_temp
    cpu_usage=$(get_cpu_usage)
    cpu_temp=$(get_cpu_temp)

    read -r ram_total ram_used ram_free ram_percent <<< "$(get_ram_stats)"

    local gpu_json
    gpu_json=$(get_gpu_json)

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

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