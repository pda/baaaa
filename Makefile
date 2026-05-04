APP_NAME := Baaaa
BUNDLE_ID := net.pda.baaaa
CONFIG    := release
BUILD_DIR := .build/$(CONFIG)
APP       := $(APP_NAME).app
SIGN_IDENTITY ?= -
ENTITLEMENTS ?=

SIGN_ARGS := --force --deep --sign "$(SIGN_IDENTITY)"

ifneq ($(strip $(SIGN_IDENTITY)),-)
SIGN_ARGS += --timestamp --options runtime
endif

ifneq ($(strip $(ENTITLEMENTS)),)
SIGN_ARGS += --entitlements "$(ENTITLEMENTS)"
endif

.PHONY: all build run app open verify sign-identities clean

all: app

build:
	swift build -c $(CONFIG)

run:
	swift run -c $(CONFIG) $(APP_NAME)

app: build
	rm -rf "$(APP)"
	mkdir -p "$(APP)/Contents/MacOS"
	mkdir -p "$(APP)/Contents/Resources"
	cp "$(BUILD_DIR)/$(APP_NAME)" "$(APP)/Contents/MacOS/$(APP_NAME)"
	cp -R "$(BUILD_DIR)/$(APP_NAME)_$(APP_NAME).bundle" "$(APP)/Contents/Resources/"
	cp Resources/Info.plist "$(APP)/Contents/Info.plist"
	codesign $(SIGN_ARGS) "$(APP)"
	@echo "Built $(APP)"

open: app
	open "$(APP)"

verify: app
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
	rm -rf .build "$(APP)"
