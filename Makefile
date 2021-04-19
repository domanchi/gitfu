.PHONY: development
development: minimal requirements-dev-minimal.txt
	venv/bin/pip install -r requirements-dev-minimal.txt
	venv/bin/pre-commit install

minimal: venv/bin/activate
venv/bin/activate:
	test -d venv || python3 -m venv venv
	touch venv/bin/activate
