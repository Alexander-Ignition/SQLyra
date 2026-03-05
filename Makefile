TARGET = SQLyra
SNIPPETS := $(notdir $(basename $(wildcard Snippets/*.swift)))

.PHONY: clean lint format test-linux $(SNIPPETS) test-snippets learn preview-doc

clean:
	swift package clean
	rm -rf ./build
	rm -rf ./Snippets/db.sqlite

README.md: Playgrounds/README.playground/Contents.swift
	cat $< | ./Scripts/markdown.swift > $@

# MARK: - format

lint:
	xcrun swift-format lint --recursive --strict ./

format:
	xcrun swift-format --recursive --in-place  ./

# MARK: - Apple Tests

XCODEBUILD_TEST = xcodebuild test \
	-quiet \
	-scheme $(TARGET) \
	-resultBundlePath $@

XCCOV = xcrun xccov view --files-for-target $(TARGET) --report $@

build/test-macos.xcresult:
	$(XCODEBUILD_TEST) -destination 'platform=macOS'
	$(XCCOV)

build/test-ios.xcresult:
	$(XCODEBUILD_TEST) -destination 'platform=iOS Simulator,name=iPhone 17'
	$(XCCOV)

# MARK: - Linux Tests

# Apple Container or Docker
CONTAINER ?= container

test-linux:
	$(CONTAINER) run --rm -v "$(PWD):/src" -w /src swift:latest /bin/bash -c \
	"apt-get update && apt-get install -y libsqlite3-dev && swift test"

# MARK: - Snippets

$(SNIPPETS):
	swift run --quiet $@

run-snippets: $(SNIPPETS)

learn:
	SWIFTPM_ENABLE_SNIPPETS=1 swift package learn

# MARK: - DocC

build/docs:
	env SQLYRA_DOCС_PLUGIN=1 \
		swift package --allow-writing-to-directory $@ \
		generate-documentation \
		--target $(TARGET) \
		--transform-for-static-hosting \
		--hosting-base-path $(TARGET) \
		--output-path $@

preview-doc:
	env SQLYRA_DOCС_PLUGIN=1 \
		swift package --disable-sandbox \
		preview-documentation --target $(TARGET)
