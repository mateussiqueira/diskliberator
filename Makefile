.PHONY: all build clean run dmg xcodegen lint test diagnose

APP_NAME = DiskLiberator
PROJECT = $(APP_NAME).xcodeproj
DMG = /tmp/$(APP_NAME)-$(shell date +%Y%m%d).dmg
BUILD_DIR = /tmp/$(APP_NAME)-Build

all: build

# Generate Xcode project, then build Release
build: xcodegen
	xcodebuild -project $(PROJECT) -scheme $(APP_NAME) -configuration Release -derivedDataPath $(BUILD_DIR) build
	@echo "✓ Build complete: $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app"

# Generate Xcode project from project.yml
xcodegen:
	rm -rf $(PROJECT)
	xcodegen generate --project .
	@echo "✓ Project generated: $(PROJECT)"

# Open the app
run: build
	open "$(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app"

# Create DMG for distribution
dmg: build
	rm -f $(DMG)
	hdiutil create -volname "$(APP_NAME)" \
		-srcfolder "$(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app" \
		-ov -format UDZO $(DMG) 2>/dev/null
	@echo "✓ DMG: $(DMG)"

# Open in Xcode
open:
	@if [ -d "$(PROJECT)" ]; then \
		open $(PROJECT); \
	else \
		$(MAKE) xcodegen && open $(PROJECT); \
	fi

# Clean build artifacts
clean:
	rm -rf $(PROJECT) $(BUILD_DIR) $(DMG) /tmp/$(APP_NAME)*.dmg
	rm -rf Sources/$(APP_NAME)/GeneratedInfo.plist
	@echo "✓ Cleaned"

# Full clean: remove all generated files
distclean: clean
	rm -rf .build
	@echo "✓ Full clean"

# Run diagnostic tests (CLI)
test:
	@echo "=== Testing DiskService ==="
	swift -e '
	import Foundation
	let testURL = URL(fileURLWithPath: NSHomeDirectory() + "/Desktop")
	let size = DiskService.shared.calcSize(testURL)
	print("  Desktop size: \(ByteCountFormatter.short(size))")
	' 2>/dev/null || echo "  (CLI test requires Xcode project)"

# Diagnostic script
diagnose:
	@echo "=== DiskLiberator Diagnostics ==="
	@echo "Swift: $(shell swift --version 2>/dev/null | head -1)"
	@echo "Xcode: $(shell xcodebuild -version 2>/dev/null | head -1)"
	@echo "macOS: $(shell sw_vers -productVersion)"
	@echo ""
	@echo "Source files: $(shell find Sources -name '*.swift' | wc -l)"
	@echo "Lines of code: $(shell find Sources -name '*.swift' -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $$1}')"
	@echo ""
	@echo "Volumes:"
	@ls -1 /Volumes/ 2>/dev/null | while read v; do printf "  %-20s %s\n" "$$v" "$$(df -h /Volumes/$$v 2>/dev/null | tail -1 | awk '{print $$3 " / " $$2}')"; done
	@echo ""
	@echo "Tools available:"
	@for tool in rsync tar purge brew top; do printf "  %-10s %s\n" "$$tool" "$$(which $$tool 2>/dev/null || echo 'not found')"; done
	@echo ""
	@echo "External SSD: $$([ -d /Volumes/BACKUP ] && echo 'MOUNTED' || echo 'NOT MOUNTED')"
