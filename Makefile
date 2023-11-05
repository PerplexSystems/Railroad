MLTON = mlton
SMLFMT = smlfmt

SOURCES = $(wildcard src/*.sml) $(wildcard src/*.mlb) $(wildcard src/**/*.sml) $(wildcard src/**/*.mlb)
TESTS_SOURCES = $(SOURCES) $(wildcard tests/*.sml) $(wildcard tests/*.mlb) $(wildcard tests/**/*.sml) $(wildcard tests/**/*.mlb)

all: build/railroad

build:
	mkdir $@

build/railroad: $(SOURCES) build
	$(MLTON) -output $@ src/railroad.mlb

build/tests: $(TESTS_SOURCES) build
	$(MLTON) -output $@ tests/tests.mlb

test: build/tests
	./build/tests

format: $(SOURCES) $(TEST_SOURCES)
	$(SMLFMT) --force **/*.mlb

clean:
	rm -f build/railroad
	rm -f build/railroad-tests

.PHONY: all clean test
