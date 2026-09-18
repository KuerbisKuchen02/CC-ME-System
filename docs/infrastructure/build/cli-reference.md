
# Infrastructure CLI Quick Reference

General

```bash
cc <command> <selector> [filters]
```

Commands:

```txt
build
test
deploy
verify
```

Execution:

```txt
parse → select → sort → display selection → execute → summarize
```

Selected entries are sorted alphabetically by fully qualified identifier and executed sequentially.

An empty selection is valid: nothing executes and the CLI explains that nothing matched.

Selectors

| Selector                   | Meaning                |
| -------------------------- | ---------------------- |
| `all`                      | All projects           |
| `lib.all`                  | All shared libraries   |
| `external.all`             | All external libraries |
| `<project-name>`           | One project            |
| `lib.<library-name>`       | One shared library     |
| `external.<external-name>` | One external library   |

Build Targets are not selectors.

Examples:

```bash
cc build project1
cc build lib.all
cc build external.all
```

## `build`

```txt
cc build <selector>
    [--type <development|test|release>]
    [--target <glob>]
    [--group <glob>]
```

| Parameter  | Valid values               | Glob | Default     |
| ---------- | -------------------------- | ---- | ----------- |
| `--type`   | development, test, release | No   | development |
| `--target` | Build Target name          | Yes  | default     |
| `--group`  | Build Group name           | Yes  | none        |

Examples:

```bash
cc build project1
cc build project1 --type release
cc build project1 --target plugin-*
cc build project1 --type release --target plugin-*
cc build lib.all --target '*'
```

## `test`

```txt
cc test <selector>
    [--target <glob>]
    [--group <glob>]
    [--test-filter <filter-expression>]
```

| Parameter       | Valid values           | Glob            |
| --------------- | ---------------------- | --------------- |
| `--target`      | Build Target name      | Yes             |
| `--group`       | Build Group name       | Yes             |
| `--test-filter` | Test filter expression | See test syntax |

Default target: `default`.

Test filter:

```txt
<suite>.<case>
```

Both suite and case support `*`.

Positive expressions use `:`:

```txt
TestMath.testAdd:TestString.*
```

Negative expressions follow `-`:

```txt
TestMath.*-TestMath.testSlow
```

No positive expression means all tests first:

```txt
-*.testSlow
```

Examples:

```bash
cc test project1
cc test project1 --target plugin-*
cc test project1 --test-filter "TestMath.*"
cc test project1 --test-filter "-*.testSlow"
```

## `deploy`

```txt
cc deploy <selector>
    [--deployment-target <name>]
```

| Parameter             | Valid values           | Glob | Default |
| --------------------- | ---------------------- | ---- | ------- |
| `--deployment-target` | Deployment Target name | No   | default |

The Deployment Target defines:

```txt
method
destination
build_type
```

Examples:

```bash
cc deploy project1
cc deploy project1 --deployment-target release-git
```

If default does not exist, explicitly select a configured Deployment Target or create one named `default`.

## `verify`

```txt
cc verify <selector>
    [--build-type <development|test|release>]
    [--build-target <glob>]
    [--build-group <glob>]
    [--deployment-target <name>]
```

| Parameter             | Valid values               | Glob |
| --------------------- | -------------------------- | ---- |
| `--build-type`        | development, test, release | No   |
| `--build-target`      | Build Target name          | Yes  |
| `--build-group`       | Build Group name           | Yes  |
| `--deployment-target` | Deployment Target name     | No   |

Verify uses explicit names; the build-only short forms `--type`, `--target`, and `--group` are not used.

Examples:

```bash
cc verify project1 --build-type release
cc verify project1 --build-type test --build-target plugin-*
cc verify project1 --deployment-target release-git
```

A verify invocation must explicitly identify a workflow. If neither a build workflow nor Deployment Target is specified, the CLI reports an error and explains how to provide one.

## Glob Rules

Glob patterns are supported for:

```txt
--target
--group
--build-target
--build-group
```

Glob patterns are not supported for:

```txt
--type
--build-type
--deployment-target
```

Build types are exact enumerated values. Deployment Targets are exact named configurations.

## Selection and Summary

Before execution:

```txt
Selection:
  project1 / default
  project1 / plugin-a
  project1 / plugin-ui
```

After execution:

```txt
Build summary:
  project1 / default   ✓
  project1 / plugin-a ✓
  project1 / plugin-ui ✗

Result:
  2 builds successful
  1 build failed
```

Empty selection:

```txt
Selection:
  No entries matched the selector and filters.

Nothing to execute.
Check that the selector and filters are defined as expected.

Build summary:
  0 builds executed

Common Commands:
cc build project1
cc build project1 --type release
cc build project1 --target plugin-*
cc test project1
cc test project1 --test-filter "TestMath.*"
cc test project1 --test-filter "-*.testSlow"
cc deploy project1
cc deploy project1 --deployment-target release-git
cc verify project1 --build-type release
cc verify project1 --deployment-target release-git
```
