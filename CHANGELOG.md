## 1.1.0

- import now supports relative paths, e.g. `import "../rel/path/to/module.sh"`
- stracktrace.print will now exit with code 1 and do nothing if no strack file
  exists
- tty now exports `TTY_TICK` for a unicode tick

## 1.0.3

- is now compatible with bash 3.2 (macOS Sierra)
- `bb/nprintf.sh` a new contender for nice formatting of multiline messages
- `bb/platform.sh` has been broken down into `bb/env.sh` for sniffing available
  functions and commands in the environment as well as sourcing the profile,
  and `bb/os.sh` for sniffing the host OS.

## 1.0.2

- `bb/invariant.sh` no longer accepts a "predicate" as a string to be evaluated
  due to its lack of reliability. Instead, now it is expected to be called with
  an _evaluation_ of something that yields a boolean like `$([[ ... ]])` or
  `$(test ...)`. On mis-use, it will print a stack trace to guide the user to
  the offending routine.

## 1.0.0

- `bb/import.sh` is now able to import modules from github!
- `bb/import.sh` now accepts a "pedantic" flag that causes it to exit the
  process with code 1 when it fails to resolve a module (**not when the module
  itself, if resolved, fails to evaluate!**)
- `bb/stracktrace.sh` will now print 5 frames up from 3