# API Documentation

## Layout

```
gitfu
  |- main.sh                       # The main entry point to the framework
  |- common/                       # Collection of utility functions, organized by
  |                                  library name (eg. string, array)
  |
  |- scripts/                      # Self-contained scripts for easier git usage
  |
  |- <custom_function_name>/       # Custom git functions modules
```

All sub-folders SHOULD have a `main.sh` as the central access point to execute that functionality (except for `gitfu/scripts`). In addition, all bash scripts SHOULD be executable on their own (though, they may not provide complete functionality; eg. `common` scripts). By doing so, they will be easier to test, saner to read, and able to be cross-functional (without worrying about namespaced functions when you're `source`-ing **everything**).

Functions can utilize two methods of returning data:

1. **Return Code**
   This is an integer value, signifying the success/failure of a function. As per bash standards, a return code of `0` signifies success or `true`, while a return code of `1` signifies some sort of failure. Any function that deviates from this norm MUST write a doc-string to enumerate return codes, and their meanings.

   The root `main.sh` MUST either return 0 (for success) or 1 (for failure).

2. **`echo`-ed String.**
   This is a string value, that allows more flexibility in return values from bash functions. Their use is demonstrated in the code snippet below:

   ```bash
   function foobar() {
     # Usage: foobar <string>
     # TODO: Test
     echo "foo-${1}-bar"
   }

   function main() {
     # NOTE: `foobar` is called within a subshell, such that its output will be captured
     #       and saved within $var. In this way, we can utilize bash functions effectively
     #       to return non-integer values.
     local var
     var=$(foobar "shoddy")
     
     echo "$var"	# will return `foo-shoddy-bar`
   }

   main
   ```

**Gotcha**: If you want to utilize BOTH a return value and an echo'ed string, you MUST declare `local` on a separate line than the variable assignment. See the example below:

```bash
function foobar() {
  echo "foo-${1}-bar"
  return 1
}

function incorrect_example() {
  local var=$(foobar "get")
  echo $?	# will return `0`, because `local` is the last operation that is performed.
}

function correct_example() {
  local var
  var=$(foobar "down")
  echo $?	# will return `1`
}
```



## Modules

### /main.sh

This script is responsible for (in this order):

1. Modifying initial git commands, so they are compatible with the framework.
2. Applying additional functionality on top of existing git commands (eg. WIP commit)
3. Routing custom git commands to the various custom modules.

If you're adding a custom module/functionality, it should be exposed to the user through this script.

### Common Functionality

This module attempts to make developing easier (and saner) by providing common functionality that can be used by all scripts. To execute these, simply run the relevant shell script, with the function you want to call, and any other arguments that the function requires.

For example,

```bash
var=`$GITFU_BASE/gitfu/common/string.sh "getStringLength" "foo"`
echo "$var"     # will output `3`
```

### Scripts

These are self-contained scripts that can be run ad-hoc (without going through the git wrapper at `main.sh`). These scripts SHOULD have the following API layout:

```bash
function usage() {
  echo "This prints out a terminal-friendly, human-readable description of how to use the script."
  echo "It should also describe any flags that the script may interpret."
}

# Any other functions, as required.

function main() {
  # The main functionality of the code goes here.
}

main "$@"
```

These scripts can also import functionality from other scripts/modules in the framework, although if it heavily depends on a certain subset of scripts/modules, perhaps it should be classified as a separate custom module altogether.

### Custom Modules

These are a collection of bash scripts written for one common purpose, and are often accessible through a custom git command. Eg. `git sync` provides the functionality to synchronize your local git repo with a specified remote git repo.

Write documentation for their individual usage in `docs/<custom_function_name>.md`.
