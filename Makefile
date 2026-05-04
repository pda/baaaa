APP_NAME := Baaaa
BUNDLE_ID := net.pda.baaaa
CONFIG    := release
BUILD_DIR := .build/$(CONFIG)
APP       := $(APP_NAME).app
ZIP       := $(APP_NAME).zip
SIGN_IDENTITY ?= -
SIGN_KEYCHAIN ?=
ENTITLEMENTS ?=
NOTARY_PROFILE ?=
NOTARY_KEYCHAIN ?=

SIGN_ARGS := --force --deep --sign "$(SIGN_IDENTITY)"
NOTARY_SUBMIT_ARGS := --keychain-profile "$(NOTARY_PROFILE)"

ifneq ($(strip $(SIGN_IDENTITY)),-)
SIGN_ARGS += --timestamp --options runtime
endif

ifneq ($(strip $(SIGN_KEYCHAIN)),)
SIGN_ARGS += --keychain "$(SIGN_KEYCHAIN)"
endif

ifneq ($(strip $(ENTITLEMENTS)),)
SIGN_ARGS += --entitlements "$(ENTITLEMENTS)"
endif

ifneq ($(strip $(NOTARY_KEYCHAIN)),)
NOTARY_SUBMIT_ARGS += --keychain "$(NOTARY_KEYCHAIN)"
endif

JUNIT_PATH ?= .build/junit.xml

.PHONY: all build test test-junit run app zip notarize open verify sign-identities clean

all: app

build:
	swift build -c $(CONFIG)

test:
	swift test -c $(CONFIG)

# Run the test suite and emit a JUnit XML report for Buildkite Test Engine.
# Disables XCTest because, when both runners are enabled, --xunit-output is
# claimed by XCTest and the swift-testing results are dropped.
test-junit:
	mkdir -p "$(dir $(JUNIT_PATH))"
	rm -f "$(JUNIT_PATH)"
	swift test -c $(CONFIG) \
		--enable-swift-testing --disable-xctest \
		--xunit-output "$(JUNIT_PATH)"

run:
	swift run -c $(CONFIG) $(APP_NAME)

app: build
	rm -rf "$(APP)"
	mkdir -p "$(APP)/Contents/MacOS"
	mkdir -p "$(APP)/Contents/Resources"
	cp "$(BUILD_DIR)/$(APP_NAME)" "$(APP)/Contents/MacOS/$(APP_NAME)"
	cp -R "$(BUILD_DIR)/$(APP_NAME)_$(APP_NAME).bundle" "$(APP)/Contents/Resources/"
	cp "Resources/AppIcon.icns" "$(APP)/Contents/Resources/AppIcon.icns"
	cp Resources/Info.plist "$(APP)/Contents/Info.plist"
	codesign $(SIGN_ARGS) "$(APP)"
	@echo "Built $(APP)"

zip: app
	rm -f "$(ZIP)"
	ditto -c -k --sequesterRsrc --keepParent "$(APP)" "$(ZIP)"
	@echo "Built $(ZIP)"

notarize: zip
	@if [ -z "$(NOTARY_PROFILE)" ]; then \
		echo "Set NOTARY_PROFILE to a notarytool keychain profile name"; \
		exit 2; \
	fi
	xcrun notarytool submit "$(ZIP)" $(NOTARY_SUBMIT_ARGS) --wait
	xcrun stapler staple "$(APP)"
	xcrun stapler validate "$(APP)"
	rm -f "$(ZIP)"
	ditto -c -k --sequesterRsrc --keepParent "$(APP)" "$(ZIP)"
	spctl --assess --type execute --verbose=2 "$(APP)"
	@echo "Notarized $(APP) and rebuilt $(ZIP)"

open: app
	open "$(APP)"

verify: app test
	codesign --verify --deep --strict --verbose=2 "$(APP)"
	@if [ "$(SIGN_IDENTITY)" = "-" ]; then \
		echo "Skipping Gatekeeper assessment for ad hoc signature"; \
	elif echo "$(SIGN_IDENTITY)" | rg -q '^Developer ID Application:'; then \
		spctl --assess --type execute --verbose=2 "$(APP)"; \
	else \
		echo "Skipping Gatekeeper assessment for non-Developer ID signature"; \
	fi

sign-identities:
	security find-identity -v -p codesigning

clean:
	rm -rf .build "$(APP)" "$(ZIP)"
