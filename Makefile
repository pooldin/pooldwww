# Magical make incantations...
.DEFAULT_GOAL := deps

.PHONY: assets clean css css-debug deps js js-all js-debug js-lib \
	    js-lib-debug run shell ipy bpy tests


RUN=foreman run
MANAGE=$(RUN) python manage.py


assets:
	@$(MANAGE) assets rebuild

clean:
	@find . -name "*.py[co]" -exec rm -rf {} \;

css:
	@$(MANAGE) assets rebuild -b pooldin-css -b pooldin-css-min

css-debug:
	@$(MANAGE) assets rebuild -b pooldin-css

deps:
	@easy_install readline
	@$(RUN) python setup.py dev
	@pip install -r dev/requirements.txt

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
