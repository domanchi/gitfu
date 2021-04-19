# CONTRIBUTING

## Layout

```
gitfu
  |- commands           # git function shims. exposed through `git <command>`
  |- core               # core functionality for `gitfu`
  |- standalone         # standalone scripts. exposed through console-scripts when pip installed
```

## Testing

All manual.

## Deploying

TODO

### Manual Testing of Installing from Python Wheel

```bash
# First, we need to build a wheel
$ python setup.py bdist_wheel --universal

# Then, we can install from that wheel
$ pip install --only-binary :all: --no-cache -f file:///`pwd`/dist gitfu

# Clean up after ourselves
rm -r build dist
```
