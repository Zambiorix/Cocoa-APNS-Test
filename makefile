all: build install dmg

build:
	xcodebuild CONFIGURATION_BUILD_DIR=$$PWD/build/ clean build -project APNSTest.xcodeproj -scheme APNSTest -configuration Release -arch x86_64

install:
	sudo cp -a ./build/*.app /Applications/

dmg:
	hdiutil create -srcfolder build/*.app -volname "APNSTest" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW build/APNSTest.dmgo

.PHONY: build