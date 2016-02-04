.PHONY: clean draft final

INPUT=manuscript.org
HTML_OUTPUT=$(patsubst %.org, %.html, $(INPUT))
TARGET=$(patsubst %.org, html/%.html, $(INPUT))

# Extract all multi SVG images from svg/ folder into img/ folder.  Copy plain
# SVG so that all reside in img/.
SVG_SRC=$(wildcard svg/*.svg)
SVG_DST=$(patsubst svg/%.svg, img/%.svg, $(SVG_SRC))
PNG_DST=$(patsubst svg/%.svg, img/%.png, $(SVG_SRC))

draft: $(TARGET) $(SVG_DST)
final: $(TARGET) $(SVG_DST)

$(TARGET): $(INPUT) refs.bib html-export-setup.el
	@echo 'Exporting to HTML...'
	@emacs --quick --batch \
         --load html-export-setup.el \
         --file $(INPUT) \
         --eval '(message (format "Org version %s" (org-version)))' \
         --eval '(org-html-export-to-html)'

# Org creates the HTML in the same directory as the Org document.  Maybe there
# is a way to override it with ELisp, but for now...
	mv $(HTML_OUTPUT) $(TARGET)

# Extract individual SVG from SVG containing multiple diagrams with Inkscape.
img/%.multi.svg: svg/%.multi.svg svgsplit
	./svgsplit svg $< img
  # We actually create multiple files, and we can't know their names from the
  # Makefile.  So we use a phony file to know when we need to keep track of
  # the last time we ran the command.
	@touch $@

img/%.svg: svg/%.svg
	cp $< $@

# Same as above, but for the PNG exports.
img/%.multi.png: svg/%.multi.svg svgsplit
	./svgsplit png $< img
	@touch $@

img/%.png: svg/%.svg
	rsvg-convert --format png --output $@ $<

clean:
	rm --force $(TARGET)
	rm --force img/*.svg
	rm --force img/*.png
	rm --force img/*.pdf
