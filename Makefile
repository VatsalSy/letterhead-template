SHELL := /bin/sh

LATEXMK ?= latexmk
LATEXMK_FLAGS := -norc -pdf -interaction=nonstopmode -halt-on-error -synctex=1

.DEFAULT_GOAL := all

.PHONY: all clean

all:
	@set -eu; \
	found=0; \
	for tex in ./*.tex; do \
		[ -f "$$tex" ] || continue; \
		found=1; \
		$(LATEXMK) $(LATEXMK_FLAGS) "$$tex"; \
		$(LATEXMK) -norc -c "$$tex"; \
		$(RM) "$${tex%.tex}.synctex.gz"; \
	done; \
	if [ "$$found" -eq 0 ]; then \
		echo "No TeX files found in $$(pwd)" >&2; \
		exit 1; \
	fi

clean:
	@set -eu; \
	for tex in ./*.tex; do \
		[ -f "$$tex" ] || continue; \
		$(LATEXMK) -norc -c "$$tex"; \
		$(RM) "$${tex%.tex}.synctex.gz"; \
	done
