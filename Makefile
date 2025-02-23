.PHONY: generate-coredata clean build

# Определяем пути
PROJECT_DIR := $(shell cd .. && pwd)
XCODEBUILD := xcodebuild
PROJECT := $(PROJECT_DIR)/Diploma.xcodeproj
SCHEME := Diploma

generate-coredata:
	./Scripts/generate_coredata.sh

clean:
	cd $(PROJECT_DIR) && $(XCODEBUILD) -project $(PROJECT) -scheme $(SCHEME) clean

build:
	cd $(PROJECT_DIR) && $(XCODEBUILD) -project $(PROJECT) -scheme $(SCHEME) build

update-coredata: generate-coredata build 