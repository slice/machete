# Machete

> [!NOTE]
> Work in progress.

A reverse engineering multi-tool for Apple platforms.

## Usage

Machete is developed against Swift 6.2 (Spring 2025; Xcode 26 or later).

### Searching for Images

By default, the shared cache currently in memory is searched. Support for remote shared caches is forthcoming.

```sh
# Print out the Mach-O image named "appkit" (case-insensitively matching) along with all of its load commands.
swift run machete image list -n appkit --print-load-commands

# Print out all Mach-O images that case-insensitively contain "mathtypesetting" in a string representation of their load commands.
# This can essentially be used to determine the set of images that link to a certain image.
swift run machete image list --loading mathtypesetting
```