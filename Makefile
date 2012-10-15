# Magical make incantations...
.DEFAULT_GOAL := deps

.PHONY: assets build clean css css-debug deps dist js js-all js-debug js-lib \
	    js-lib-debug run shell ipy bpy tests upload


RUN=foreman run
SETUP=$(RUN) python setup.py
MANAGE=$(RUN) python manage.py


assets:
	@$(MANAGE) assets rebuild

build:
	@$(SETUP) build

clean:
	@find . -name "*.py[co]" -exec rm -rf {} \;
	@$(SETUP) clean
	@rm -rf dist build

css:
	@$(MANAGE) assets rebuild -b pooldin-css -b pooldin-css-min

css-debug:
	@$(MANAGE) assets rebuild -b pooldin-css

deps:
	@$(SETUP) dev

dist: clean assets
	@$(SETUP) sdist

js:
	@$(MANAGE) assets rebuild -b pooldin-js -b pooldin-js-min

js-all: js-lib js

js-debug:
	@$(MANAGE) assets rebuild -b pooldin-js

js-lib:
	@$(MANAGE) assets rebuild -b libs-js -b libs-js-min

js-lib-debug:
	@$(MANAGE) assets rebuild -b libs-js

run:
	@foreman start -f dev/Procfile

run-test:
	@foreman start

shell:
	@foreman run python manage.py shell

ipy:
	@foreman run python manage.py shell -i

bpy:
	@foreman run python manage.py shell -b

tests:
	@python manage.py tests

upload: clean assets
	@$(SETUP) sdist upload -r pooldin
