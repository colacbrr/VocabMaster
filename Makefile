help:
	@printf "%s\n" \
		"run      Run the Flutter app" \
		"analyze  Run flutter analyze" \
		"test     Run flutter test" \
		"gen      Regenerate Hive adapters"

run:
	flutter run

analyze:
	flutter analyze

test:
	flutter test

gen:
	flutter pub run build_runner build --delete-conflicting-outputs
