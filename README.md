# `dirc` Method Documentation

## Overview

The `dirc` function is a directory traversal and file processing tool. It creates a hierarchical directory structure, extracts file content or declarations, and outputs results in YAML or JSON formats. The tool excludes unnecessary directories like `node_modules` and provides clipboard functionality.

## Features

- Supports filtering by file patterns and extensions (e.g., `.swift`, `.js`, `.py`).
- Excludes `node_modules` and `Resources` by default.
- Builds a hierarchical directory structure.
- Extracts declarations like classes, functions, or protocols.
- Outputs in YAML (default) or JSON formats.
- Copies results directly to the clipboard.
- Allows traversal depth limits.

## Usage

### Syntax

```dirc [options] [file patterns]```

### Options

`-d`: Extract declarations only (e.g., classes, functions, etc.).

`-c`: Extract the content of matched files.

`-json`: Output results in JSON format (default is YAML).

`-L<number>`: Limit the depth of directory traversal.


## Examples

Generate a file tree in YAML format:

```dirc```

Extract declarations from `.swift` files:

```dirc -d *.swift```

Fetch file content in JSON format (YAML is default except for -c commmands due to YAML restrictions around line escapes :

```dirc -d -json ```

Limit directory depth to two levels:

`dirc -L2`

Specify file names:

`dirc "App, MainView"`

## Implementation Details

The function processes options and file patterns to determine its mode of operation. It can:

- Recursively traverse directories, excluding `node_modules`, to match patterns.
- Build a directory tree using supported file types like `swift`, `js`, `ts`, `jsx`, `tsx`, `cpp`, `h`, `py`, `m`, and `mm`.
- Extract content or declarations using regular expressions.

The output is either a directory structure or extracted information in YAML or JSON formats, copied to the clipboard for convenience.

## Notes

The output is automatically copied to the clipboard using `pbcopy`. Unsupported file extensions are ignored. Depth limiting applies only to directory traversal and not to file matching.
pbcopy must be installed, however it is usually built into macos

This tool is designed for developers who need to manage large codebases effectively.
