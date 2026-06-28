#!/bin/bash
echo "=== DiskLiberator System Diagnostics ==="
echo ""
echo "--- macOS ---"
sw_vers 2>/dev/null
echo ""
echo "--- Xcode ---"
xcodebuild -version 2>/dev/null | head -2 || echo "Xcode not found"
echo ""
echo "--- Tools ---"
for cmd in swift xcodegen rsync tar purge brew hdiutil; do
    if which "$cmd" &>/dev/null; then
        echo "  ✓ $cmd : $(which $cmd)"
    else
        echo "  ✗ $cmd : not found"
    fi
done
echo ""
echo "--- Swift ---"
swift --version 2>/dev/null | head -1 || echo "Swift not found"
echo ""
echo "--- Volumes ---"
df -h / 2>/dev/null | tail -1 | awk '{printf "  Internal: %s used / %s total (%s free)\n", $3, $2, $4}'
ls -1 /Volumes/ 2>/dev/null | while read v; do
    info=$(df -h "/Volumes/$v" 2>/dev/null | tail -1 | awk '{printf "%s used / %s total", $3, $2}')
    echo "  External: $v ($info)"
done
echo ""
echo "--- RAM ---"
vm_stat 2>/dev/null | head -10
echo ""
echo "--- DiskLiberator Project ---"
if [ -d /Volumes/BACKUP/projects/mac-cleanup-app ]; then
    echo "  Location: /Volumes/BACKUP/projects/mac-cleanup-app"
    echo "  Swift files: $(find /Volumes/BACKUP/projects/mac-cleanup-app/Sources -name '*.swift' | wc -l)"
fi
echo ""
echo "=== Diagnostics Complete ==="
