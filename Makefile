TARGET := ramsete-unicycle-controller.pdf

# Make does not offer a recursive wildcard function, so here's one:
rwildcard=$(wildcard $1$2) $(foreach dir,$(wildcard $1*),$(call rwildcard,$(dir)/,$2))

# Python files that generate SVG files
PY := $(filter-out ./bookutil/% ./build/% ./lint/%,$(call rwildcard,./,*.py))
PY_STAMP := $(addprefix build/,$(PY:.py=.stamp))

BIB := $(wildcard *.bib)
SVG := $(wildcard *.svg)
PDF_TEX := $(SVG:.svg=.pdf_tex)

.PHONY: all
all: $(TARGET)

$(TARGET): $(basename $(TARGET)).tex $(PY_STAMP) $(BIB)
	latexmk -interaction=nonstopmode -xelatex $(basename $@)

$(PY_STAMP): build/%.stamp: %.py
	@mkdir -p $(@D)
	cd $(@D) && python $(abspath ./$<) --noninteractive
	@touch $@

%.pdf_tex: %.svg
	inkscape -D -z --file=$< --export-pdf=$(basename $<).pdf --export-latex

.PHONY: format
format:
	./lint/format_bibliography.py
	./lint/format_eol.py
	./lint/format_paragraph_breaks.py
	python3 -m black -q .

.PHONY: lint
lint: format
	./lint/check_filenames.py
	./lint/check_tex_includes.py
	./lint/check_tex_labels.py
	./lint/check_links.py
	git --no-pager diff --exit-code HEAD  # Ensure formatter made no changes

.PHONY: clean
clean: clean_tex
	rm -rf build

.PHONY: clean_tex
clean_tex:
	latexmk -xelatex -C
	rm -f $(TARGET)

.PHONY: upload
upload:
	rsync --progress $(TARGET) file.tavsys.net:/srv/file/control/$(TARGET)

.PHONY: setup_arch
setup_arch:
	sudo pacman -Sy --needed --noconfirm \
		base-devel \
		biber \
		inkscape \
		texlive-bibtexextra \
		texlive-core \
		texlive-latexextra \
		python \
		python-black \
		python-pip \
		python-requests

.PHONY: setup_ubuntu
setup_ubuntu:
	sudo apt-get update -y
	sudo apt-get install -y \
		biber \
		build-essential \
		cm-super \
		inkscape \
		latexmk \
		texlive-bibtex-extra \
		texlive-latex-extra \
		texlive-xetex \
		python3 \
		python3-pip \
		python3-requests \
		python3-setuptools
	# The Ubuntu 24.04 packages are too old
	# Python packages
	#   * black (to format Python source code)
	#   * pylint (for Python linting)
	pip3 install --user --break-system-packages autoflake black==24.3.0 frccontrol==2024.22 pylint robotpy-wpimath==2025.3.2
