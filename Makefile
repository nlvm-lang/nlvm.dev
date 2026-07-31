
.phony: all build compile raster wallpaper server publish

all: raster compile build

# Wallpapers. The generator is NL; paths inside it are relative to the repo
# root, so unlike `raster` this does not delegate to brand/Makefile.
WP := brand/generated/wallpaper
wallpaper:
	nlc brand/nl -o brand/Wallpaper.nlp
	nlvm brand/Wallpaper.nlp
	rsvg-convert -w 2560 -h 1440 $(WP)-a-field.svg -o $(WP)-a-field-2560x1440.png
	rsvg-convert -w 2560 -h 1440 $(WP)-b-sheet.svg -o $(WP)-b-sheet-2560x1440.png
	rsvg-convert -w 2560 -h 1440 $(WP)-c-echo.svg  -o $(WP)-c-echo-2560x1440.png
	rsvg-convert -w 2560 -h 1440 $(WP)-d-lumen.svg -o $(WP)-d-lumen-2560x1440.png
	rsvg-convert -w 3840 -h 2160 $(WP)-a-field.svg -o $(WP)-a-field-3840x2160.png
	rsvg-convert -w 3840 -h 2160 $(WP)-b-sheet.svg -o $(WP)-b-sheet-3840x2160.png
	rsvg-convert -w 3840 -h 2160 $(WP)-c-echo.svg  -o $(WP)-c-echo-3840x2160.png
	rsvg-convert -w 3840 -h 2160 $(WP)-d-lumen.svg -o $(WP)-d-lumen-3840x2160.png

raster:
	$(MAKE) -C brand all

compile:
	nlc src/nl -o Build.nlp

build:
	nlvm Build.nlp

server:
	python3 -m http.server -d docs/

publish:
	gitagent -y
	git push

