#!/bin/bash
set -e

GODOT=${GODOT:-godot3}
VERSION=$(grep 'config/version=' project.godot | sed 's/config\/version="v\(.*\)"/\1/')
ROOT_DIR=$(pwd)

PRESETS=("windows"        "mac"            "linux"             "html5"     "android")
FILES=(  "FlappyRace.exe" "FlappyRace.zip" "FlappyRace.x86_64" "index.html" "FlappyRace.apk")

FILTER="$1"
if [ -n "$FILTER" ]; then
    found=false
    for p in "${PRESETS[@]}"; do
        if [ "$p" = "$FILTER" ]; then found=true; break; fi
    done
    if [ "$found" = false ]; then
        echo "Unknown preset '$FILTER'. Valid presets: ${PRESETS[*]}" >&2
        exit 1
    fi
fi

for i in "${!PRESETS[@]}"; do
    preset="${PRESETS[$i]}"
    if [ -n "$FILTER" ] && [ "$preset" != "$FILTER" ]; then continue; fi
    dir="builds/${preset}"
    file="${FILES[$i]}"

    echo "Exporting ${preset}..."
    rm -rf "${dir:?}"/*
    mkdir -p "$dir"
    export_flag="--export"
    if [ "$preset" = "android" ]; then
        export_flag="--export-debug"
    fi
    "$GODOT" --no-window "$export_flag" "$preset" "$dir/$file"

    echo "Zipping ${preset}..."
    dest="${ROOT_DIR}/builds/FlappyRace-${VERSION}-${preset}.zip"
    rm -f "$dest"
    if [ "$preset" = "mac" ]; then
        # Mac exports already come as a zip, so just move it
        mv -f "$dir/$file" "$dest"
    else
        (
            cd "$dir"
            zip -r "$dest" .
        )
    fi
    echo "Created $dest"
done

echo "All exports and zips complete!"
