#!/usr/bin/env bash

df -h --total -x tmpfs -x devtmpfs -x efivarfs --output=source,fstype,size,used,avail,pcent,target \
    | grep -v '/boot' | grep -v 'total'\
    | python3 -c "
        import sys, json
        lines = sys.stdin.read().strip().split('\n')
        header = lines[0].split()
        rows = [dict(zip(header, l.split())) for l in lines[1:]]
        print(json.dumps(rows, indent=2))
        "

