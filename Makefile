
.phony: all build compile raster server publish

all: raster compile build

raster:
	$(MAKE) -C brand raster_logo

compile:
	nlc src/nl -o Build.nlp

build:
	nlvm Build.nlp

server:
	python3 -m http.server -d docs/

publish:
	gitagent -y
	git push

