APP_NAME := Baaaa
BUNDLE_ID := net.pda.baaaa
CONFIG    := release
BUILD_DIR := .build/$(CONFIG)
APP       := $(APP_NAME).app

.PHONY: all build run app open clean

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
	@echo "Built $(APP)"

open: app
	open "$(APP)"

clean:
	rm -rf .build "$(APP)"
