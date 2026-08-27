SHELL := /bin/sh

LATEXMK ?= latexmk
LATEXMK_FLAGS := -norc -pdf -interaction=nonstopmode -halt-on-error -synctex=1
TEX_FILES := $(sort $(wildcard *.tex))
PDF_FILES := $(TEX_FILES:.tex=.pdf)

.DEFAULT_GOAL := all

.PHONY: all clean

all: $(PDF_FILES)
	@if [ -z "$(strip $(TEX_FILES))" ]; then \
		echo "No TeX files found in $$(pwd)" >&2; \
		exit 1; \
	fi
	@$(MAKE) --no-print-directory clean

%.pdf: %.tex
	$(LATEXMK) $(LATEXMK_FLAGS) "$<"

clean:
	@set -eu; \
	for tex in $(TEX_FILES); do \
		$(LATEXMK) -norc -c "$$tex"; \
		$(RM) "$${tex%.tex}.synctex.gz"; \
	done
