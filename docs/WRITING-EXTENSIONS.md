Theory of Operation and How to Write Extensions
===============================================



Core Features
-------------
Features defined here starting with `__` are not guaranteed stable, and should be avoided if you're trying to write functionality for kitbash outside the source tree.

`kb_log` - Print a log message prefix with the current indent for realization on stderr.

`fn_exists` - Helper to determine if a function exists in shell context.

`__compat_shim` - Emit log message ($1) and invoke function named in $2 to run $3 with all arguments from $2.

`kb_fail` - Return message prefixed with ERROR: and exit kitbash execution.

`unmeetable` - Utility for indicating an execution block is not meetable. Kitbash will stop execution when encountering this.

`process` - This will process the stanzas in a realization's is_met and optionally (non-dry-run) meet functions.

`__process_is_met` - Wrap running a realization's `is_met` function with logging.

`__process_meet` - Wrap running a realization's `meet` function with logging.

`on_change` - check for an id in the changes applied this run, and return true if found.

`requires` - as part of a realization, require another realization be loaded (and executed) first.

`__requires_nested` - realize another realization in a subshell.

`__kitbash_invoke` - this function is the real meat of kitbash. it will increment the indent level, and then `exec` the realization. This is why realizations need their own `is_met`, `meet`, and lastly, invocation to `process`. The relationship between `__kitbash_invoke` and `process` is the core of kitbash. Anything run as a local in your realization should only be a local in this invocation.

`__kitbash_load_deps`  - search filesystem paths for kitbash/babashka directories. note if the directory is a legacy 'babashka' named directory.

`__kitbash_find_deps_from_path` - inside a directory, look for files (by default ending in `.sh`) to load into kitbash. recursion my be controlled by having a `.kitbash_no_recurse` file at top directory level.

file_exsts
dir_exists
file_mtime
file_is_newer

`__kitbash_main` - check arguments and if exactly one, invoke that realization using `__kitbash_invoke`
