.PHONY: goldens fmt analyze test

goldens:
	flutter test --update-goldens

fmt:
	dart format .

analyze:
	flutter analyze

test:
	flutter test
