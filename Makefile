.PHONY: build
build:
	shards build

.PHONY: clean
clean:
	rm -rf ./bin

.PHONY: run
run: build
	./bin/url-checker
