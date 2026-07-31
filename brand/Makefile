

.PHONY: all raster_logo social

all: raster_logo social

# social-preview.png is generated — never edit it by hand, edit the SVG.
# Needs IBM Plex Mono + IBM Plex Sans installed system-wide (ibm-plex-mono.zip
# and ibm-plex-sans.zip from github.com/IBM/plex/releases, ttf/ into
# ~/.local/share/fonts/ + fc-cache -f). Without them rsvg-convert falls back
# to a system font silently and the typography breaks.
social:
	@fc-list | grep -q "IBM Plex Mono" || { echo "error: IBM Plex Mono not installed"; exit 1; }
	@fc-list | grep -q "IBM Plex Sans" || { echo "error: IBM Plex Sans not installed"; exit 1; }
	rsvg-convert -w 1280 -h 640 social-preview.svg -o social-preview.png

raster_logo:
	rsvg-convert -w 16 -h 16 nl_logo.svg -o generated/nl_logo_16.png
	rsvg-convert -w 32 -h 32 nl_logo.svg -o generated/nl_logo_32.png
	rsvg-convert -w 64 -h 64 nl_logo.svg -o generated/nl_logo_64.png
	rsvg-convert -w 128 -h 128 nl_logo.svg -o generated/nl_logo_128.png
	rsvg-convert -w 256 -h 256 nl_logo.svg -o generated/nl_logo_256.png
	rsvg-convert -w 512 -h 512 nl_logo.svg -o generated/nl_logo_512.png

	rsvg-convert -w 16 -h 16 nl_logo_letters.svg -o generated/nl_logo_letters_16.png
	rsvg-convert -w 32 -h 32 nl_logo_letters.svg -o generated/nl_logo_letters_32.png
	rsvg-convert -w 64 -h 64 nl_logo_letters.svg -o generated/nl_logo_letters_64.png
	rsvg-convert -w 128 -h 128 nl_logo_letters.svg -o generated/nl_logo_letters_128.png
	rsvg-convert -w 256 -h 256 nl_logo_letters.svg -o generated/nl_logo_letters_256.png
	rsvg-convert -w 512 -h 512 nl_logo_letters.svg -o generated/nl_logo_letters_512.png