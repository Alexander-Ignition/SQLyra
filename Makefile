TARGET_NAME = SQLyra
OUTPUD_DIR = ./Build
DERIVED_DATA_PATH = $(OUTPUD_DIR)/DerivedData

.PHONY: clean lint format test test-macos test-ios

clean:
	swift package clean
	rm -rf $(OUTPUD_DIR)

README.md: Playgrounds/README.playground/Contents.swift
	cat $< | ./Scripts/markdown.swift > $@

# MARK: - format

lint:
	xcrun swift-format lint --recursive --strict ./

format:
	xcrun swift-format --recursive --in-place  ./

# MARK: - Tests

test:
	swift test

test-macos: $(OUTPUD_DIR)/test-macos.xcresult
test-ios: $(OUTPUD_DIR)/test-ios.xcresult

XCODEBUILD_TEST = xcodebuild test -quiet -scheme $(TARGET_NAME)
XCCOV = xcrun xccov view --files-for-target $(TARGET_NAME)

$(OUTPUD_DIR)/test-macos.xcresult:
	$(XCODEBUILD_TEST) -destination 'platform=macOS' -resultBundlePath $@
	$(XCCOV) --report $@

$(OUTPUD_DIR)/test-ios.xcresult:
	$(XCODEBUILD_TEST) -destination 'platform=iOS Simulator,name=iPhone 16' -resultBundlePath $@
	$(XCCOV) --report $@

# MARK: - DocC

DOCC_ARCHIVE = $(DERIVED_DATA_PATH)/Build/Products/Debug/$(TARGET_NAME).doccarchive

$(DOCC_ARCHIVE):
	xcodebuild docbuild \
		-quiet \
		-scheme $(TARGET_NAME) \
		-destination "generic/platform=macOS" \
		-derivedDataPath $(DERIVED_DATA_PATH)

$(OUTPUD_DIR)/Docs: $(DOCC_ARCHIVE)
	xcrun docc process-archive transform-for-static-hosting $^ \
		--hosting-base-path $(TARGET_NAME) \
		--output-path $@
