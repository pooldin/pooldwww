# Magical make incantations...
.DEFAULT_GOAL := deps

.PHONY: assets build clean deps dist run shell ipy bpy tests \
		upload upload-dev upload-nightly upload-release


REV=$(shell git rev-parse --short HEAD)
TIMESTAMP=$(shell date +'%s')
RUN=foreman run
SETUP=$(RUN) python setup.py
MANAGE=$(RUN) python manage.py


assets:
	@$(MANAGE) assets rebuild

build: clean assets
	@$(SETUP) build

clean:
	@find . -name "*.py[co]" -exec rm -rf {} \;
	@$(SETUP) clean
	@rm -rf dist build

deps:
	@$(SETUP) dev

dist: clean assets
	@$(SETUP) sdist

run:
	@foreman start -f Procfile.dev

run-test:
	@foreman start

shell:
	@$(MANAGE) shell

ipy:
	@$(MANAGE) shell -i

bpy:
	@$(MANAGE) shell -b

tests:
	@$(MANAGE) tests

upload: upload-dev

upload-dev: clean assets
	@$(SETUP) egg_info --tag-build='-dev.$(TIMESTAMP).$(REV)' sdist upload -r pooldin

upload-nightly: clean assets
	@$(SETUP) egg_info --tag-date --tag-build='-dev' sdist upload -r pooldin

upload-release: clean assets
	@$(SETUP) sdist upload -r pooldin
