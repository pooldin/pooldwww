# Magical make incantations...

.DEFAULT_GOAL := deps
.PHONY := clean deps run shell ipy bpy tests

clean:
	@find . -name "*.py[co]" -exec rm -rf {} \;

deps:
	@easy_install readline
	@pip install -r requirements.txt
	@pip install -r dev/requirements.txt

run:
	@foreman start -f dev/Procfile

shell:
	@foreman run python manage.py shell

ipy:
	@foreman run python manage.py shell -i

bpy:
	@foreman run python manage.py shell -b

tests:
	@python manage.py tests
