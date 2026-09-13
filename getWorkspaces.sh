#!/usr/bin/env bash

print_workspaces() {
    hyprctl -j workspaces | jq -c '
        sort_by(.name) | map({
            key: (.address // .name),
            name: .name,
            monitor: .monitorID
        })
    '
}

print_workspaces

