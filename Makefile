
.phony: all build compile

all: compile build

compile:
	nlc src/nl -o Build.nlp

build:
	nlvm Build.nlp

server:
	python3 -m http.server -d docs/
