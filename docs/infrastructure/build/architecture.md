# Architecture of the build system, test and deployment system

## 1. Build pipeline

The build pipeline is structured into clearly separated stages to ensure modular processing and clean error isolation. Each stage has a single, well-defined responsibility:

1. **Configuration Loading & Merging**: The system loads build configurations following the configuration hierarchy (Repository → Category → Package → Target → Build Type). Merging rules apply (scalar override, map merge, and list appending/replacement/clearing).
2. **Dependency Resolution**: Static dependencies are parsed from `require()` calls and mapped to packages declared in the configuration. The dependency resolver constructs the directed dependency graph starting from the defined entry point.
3. **Dependency Validation**: The system validates the resolved dependency graph against declared package bounds, identifying any undeclared dependencies (error) or unused declared dependencies (warning).
4. **Source Packaging & Bundling**: Based on the active build type:
   - *Development / Test*: Individual modules are mapped to their logical namespaces and prepared for unbundled file emission.
   - *Release*: The static dependency closure is bundled into a single file, except for explicitly preserved files.
5. **Minification**: Release bundles are minified by stripping comments and unnecessary white spaces.
6. **Artifact Assembly & Metadata Generation**: The files are packaged, and a standard `metadata.lua` manifest is generated containing the artifact metadata and individual file checksums.

```mermaid
flowchart LR

A@{shape: start} --> B[1. Read Configuration]
B --> b@{shape: doc, label: allowed dependencies; entrypoint}
B --> C[2. Dependency Resolution]
C --> c@{shape: doc, label: Dependency Graph}
C --> D[3. Bundling]
D --> d@{shape: docs, label: bundled artifact}
D --> E[4. Minifying]
E --> e@{shape: docs, label: bundled and minified artifact}
E --> F[5. Create Installer]
F --> f@{shape: doc, label: installer.lua}
F --> G@{shape: stop}
```

## 2. Repository structure

```text
/ (Repository Root)
├── build_config.yaml                    # Repository-level configuration
├── projects/                            # Application and plugin packages
│   ├── build_config.yaml                # Category-level projects configuration
│   └── <project>/
│       ├── build_config.yaml            # Project-level configuration
│       └── src/                         # Project source files (default source_root)
├── libraries/                           # Shared library packages
│   ├── build_config.yaml                # Category-level libraries configuration
│   ├── <library>.lua                    # Small library (single file)
│   ├── <library>.build_config.yaml      # Small library sidecar configuration
│   └── <library>/
│       ├── build_config.yaml            # Large library configuration
│       └── src/                         # Large library source files
├── external/                            # External vendored packages
│   ├── build_config.yaml                # Category-level external configuration
│   ├── <package>.lua                    # Small external package (single file)
│   ├── <package>.build_config.yaml      # Small external package sidecar configuration
│   └── <package>/
│       ├── build_config.yaml            # Large external package configuration
│       └── src/                         # Large external package source files
└── build/                               # Write-only build output directory (ignored)
```

## 3. Artifact Structure

Every build target produces exactly one logical build artifact, whose output files are structured based on the active build type.

### 3.1. Bundled Artifact (Release Build Type)

In a Release build, the artifact is bundled and minified to minimize storage footprints in ComputerCraft environments:

- **Bundled Core**: All statically resolved source files in the target's dependency closure are combined into a single, main executable file. The main file is named after the target name (or after the project name if using the default target).
- **Preserved Files**: Explicitly preserved modules, directory paths, or files remain intact as separate files, preserving their relative folder structure under the project's source root.
- **FILES Manifest**: A generated `metadata.lua` file is included, which lists all files in the artifact and their SHA-256 checksums to enable installer-level verification.

### 3.2. Unbundled Artifact (Development and Test Build Types)

Development and Test builds preserve the original module structure to facilitate step-by-step debugging:

- **Preserved Module Structure**: All statically resolved source modules remain intact as individual files and keep their relative directory layout corresponding to their logical module names.
- **Unminified Sources**: Comments, formatting, and white spaces are preserved.
- **FILES Manifest**: A generated `metadata.lua` file contains artifact metadata and file checksums, identical to the Release manifest.

---

## 4. Build-configuration architecture

Example config file

```yaml
targets:
  default:
    version: 1.0.0-alpha
    entry_point: main.lua
    dependencies:
      - lib.logging
    test:
      entry_point: TestMain.lua
      dependencies:
        mode: append
        items:
          - lib.testing
```

### 4.1. Configuration hierarchy and merging

Configuration is composed in this fixed order:

```text
repository/build_config.yaml
→ projects/build_config.yaml | libraries/build_config.yaml | external/build_config.yaml
→ project/package build_config.yaml or small-package sidecar configuration
→ target
→ build type
```

The category-level configuration applies to all entries in that category. A project configuration without `targets` creates an implicit `default` target. A library configuration without `targets` is a library manifest: it supplies dependency and preserved-file settings when the library is consumed, but produces no artifact. Library targets are optional and represent independently publishable subsets.

#### Merging Behavior

- **Scalars**: A child configuration value completely overrides any inherited value from higher levels.
- **Maps**: Merged by key, with the more-specific child value winning in case of key collisions.
- **Lists**: Merged using one of three explicit list modes:
  - **Append (Default)**: Items from the child list are appended to the inherited list.
  - **Replace (`mode: replace`)**: The child list completely replaces the inherited list.
  - **Clear (`mode: clear`)**: The inherited list is entirely cleared, resulting in an empty list.

Build-target names, project names, and group names use `^[A-Za-z0-9](?:[A-Za-z0-9_]*[A-Za-z0-9])?$`. The stable target identity is `<project>/<target>`; the target name also determines its artifact name. `default` uses the project name as its artifact name.

#### Target Identity and Artifact Naming

- **Stable Identity**: The stable logical identity of a build target is `<project>/<target>`. This identity is used by the build cache, build directory, and diagnostic system.
- **Artifact Naming**: The build target name determines its output artifact name. The default target, named `default`, uses the project name as its artifact name.
- **Identifier Constraints**: Target names, project names, and group names must match the regular expression: `^[A-Za-z0-9](?:[A-Za-z0-9_]*[A-Za-z0-9])?$`.
- **Implicit Target**: A project configuration without targets creates an implicit default target. A library or external package configuration without targets behaves as a manifest only, supplying dependencies and preservation settings but generating no artifact.

### 4.2. Module Identity and Packages

The logical module name serves as a module's stable identity within the Lua ecosystem, mapping physical repository paths to import namespaces:

- **Namespaces and Prefixes**: Project modules have no prefix. Shared libraries use a `lib.` prefix (e.g., `lib.logging`). External modules use an `external.` prefix (e.g., `external.json`). Test modules use a `test.` prefix (e.g., `test.user_management.TestRegister`).
- **Source Roots**: Defaults are `source_root: src/` and `test_source_root: test/`
- **Package Shapes**: Shared libraries and external packages exist in two shapes beneath their category roots (configured by `library_search_path` and `external_search_path`, which default to `libraries/` and `external/` respectively):
  1. *Small Package*: A single file located at `libraries/<name>.lua` or `external/<name>.lua`. Small packages that require static dependencies utilize a sidecar configuration file (`libraries/<name>.build_config.yaml` or `external/<name>.build_config.yaml`
  2. *Large Package*: A package directory located at `libraries/<name>/` or `external/<name>/` containing `build_config.yaml` at its root, with its sources inside a `src/` directory.
- **Name Collisions**: A same-name small-file package and directory package within the same category (e.g., `libraries/logging.lua` and `libraries/logging/`) is a build-time resolution error.
- **Public Interfaces**: An `init.lua` file defines a public interface for its package subtree. External consumers outside the package are restricted to require *only* the public interface (e.g., `require("lib.logging")`) and are forbidden from importing internal descendants recursively. Code inside the package itself is caller-aware and is permitted to import its internal modules (e.g., `require("lib.logging.internal_module")`).

```text
libraries/logging.lua                    → lib.logging
libraries/logging/src/init.lua           → lib.logging
libraries/logging/src/format/json.lua    → lib.logging.format.json
external/example.lua                     → external.example
external/example/src/init.lua            → external.example
```

### 4.3. Artifact Selection and Layout

All build types include *only* the static dependency closure of their resolution roots; unreachable source files are omitted from the output.

- **Development Builds**: Resolve dependencies from the target's effective entry point and output the resolved closure as unbundled, unminified files under `build/<project>/artifacts/<artifact-name>/development/`.
- **Release Builds**: Resolve dependencies from the target's effective entry point, bundle and minify them into a single executable, and copy preserved files. They require a clean Git worktree, a configured repository-level `artifact_base_url`, a full source commit SHA, and a mandatory target version.
- **Test Builds**: Test builds discover `Test*.lua` files (CamelCase class-definition naming) under `test_source_root`. Every discovered suite plus the test environment and the effective test entry point are treated as dependency-resolution roots.
  - Test files use the `test.` namespace (via `test_prefix`) and are emitted below a separate `test/` runtime path to avoid colliding with production modules. Production modules retain their normal namespaces. Test artifacts are unbundled and unminified to keep source file names and line numbers useful for debugging.

#### Generated Metadata Format

Each artifact contains a generated `metadata.lua` written as an executable Lua file that returns a table of the following format:

```lua
return {
  NAME = "target_name",
  VERSION = "1.2.3",                    -- Optional for Development/Test, mandatory for Release
  SOURCE_REVISION = "<git revision>",   -- Immutable full Git commit SHA
  BASE_URL = "<artifact directory URL>", -- Base URL for deployment-facing installer downloads
  FILES = {
    { path = "main.lua", sha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" },
    ...
  }
}
```

## 5. Dependency Scope and Type

Dependency scope and dependency type are deliberately separate concepts.

**Dependency Scope**

- Target scope: available to every build type of a target.
- Build-type scope: available only to the specific build type.

The same scope distinction applies to entry points: a target may define a default entry point and a build type may override it.

**Dependency Type**

- Static: resolved by the build system and eligible for inclusion in the artifact.
- Dynamic: resolved at runtime and not included in the referencing artifact.

The resolver distinguishes them by the form of the require() argument:

- require("module.name") → static
- require(variable) → dynamic

## 6. Testing

The repository uses a test architecture based on the xUnit architecture.

Test cases are organized into test suites. A suite is therefore a collection of logically connected test cases.
A test case is divided into four phases: setup, execution, verification and teardown. In the first phase all necessary prerequisites for the test are established and the test fixture is prepared. The test fixture encompasses the set of all preconditions, test data and initialization steps required to execute a test case. The second phase involves the actual execution of the test against the system under test (SUT). The SUT refers to the software unit whose behavior is being verified in the specific test case. For example, a class, a method, a module, or an entire system. Subsequently, the next phase verifies whether the expected result has occurred. To perform the verification the test system provides a set of assertion functions. In the final phase, any persistent data is cleaned up to restore the initial state that existed prior to the test. In automatic execution, all test cases are run by a test runner. The runner can automatically discover test cases using a test discovery mechanism.

A test suite is defined as a class starting with the prefix `Test` and extending the class `TestSuite` from the `testing` library. Usually a test suite SHOULD be named the same and preserve it relative location as the source file or class being tested. For example if you want to test the class `user_management/Register` you create a test class named `TestRegister` inside a \`user\_

A test suite can contain multiple test cases, setup and teardown methods for the suite and the test cases.

A test case is defined as a method that starts with the prefix `test_`. For example \`function TestRegister:test\_

If you have multiple test that require the same setup procedure you can add a `setup()` method to the test suite class. This class is run before every test case inside this suite. The same applies to the `teardown()` method. This method is run after each test case. For initialization that needs to be executed only once for the hole test suite you can add a `setupTestSuite()` method. This method is executed before the first test case is executed. The method `teardownTestSuite()` is executed after all test cases of the suite have been executed.

If you have a test case that you want to exclude from automatic execution (for example test cases that broke because of a change and still need to be updated) you can exclude them by prefixing the test case with `DISABLED_`. The same principle can be applied to a test suite. For example \`function TestRegister:DISABLED\_

Disabling a broken test case SHOULD be preferred over commenting out a test case since disabled test cases will still be found by the test runner and are listed inside the test result as skipped test cases. This is a clear reminder that you still have to fix a test case.

Additionally you can create a test environment class at the root of the test src folder. This class inherits the class `TestEnvironment` from the `testing` library and can contain the test entry point `main()`, a environment `setup()` and `teardown()` method. The entry point method is executed before the complete test execution an can be used to configure the test system and process program parameter. Setup/ teardown methods are executed before/after the test execution. So before the first test suite/ after the last test suite.

A test listener can used to perform an action on test lifecycle and execution events. This can be used for example to output the test results to a csv file or provide additional information to the command line output. Test listeners can be registered inside the test environment entry point.

## 7. Bundling and Minification

The process of bundling and minification is not a strait forward process with many edge cases.
Since this is also a pretty standard problem with already existing solutions we can leverage such a solution to simplify implementation and focus on the important project specific requirements.

A possible implementation is provided by the [Shale bundler](https://github.com/Pyroxenium/Shale/tree/main) which is also used by the Basalt GUI framework with is a big inspiration for this repository and my own gui library.

- The bundler already included an option to declare excluded files which could work seamlessly with our preserved file approach
- The bundler also has many options to configure the release artifact which would allow us to define exactly the level of minification that we want
- The bundler also supports tree shaking what does exactly what we already doing with our unreachable file approach

## 8. Changelog System

- Changelog file per project or library
- if a changelog is present in the directory of the project it is mandatory that the changelog contains changes to be able to publish a new release
- it is also possible to use a the `changelog_path` option in a target level config to define a per target changelog file
- by default the changelog is only used for the default build target of a project
- the changelog uses the [Keep a Changelog Convention](https://keepachangelog.com/en/1.1.0/)
- for every release the version, date and git ref is recorded in the changelog
- additionally a unreleased section in the top hold all changes of the current dev version
- the changelog is manually filled with changes
- the release workflow is supported by a guided partially automatic release process
- the changelog is primarily written for humans and users of the system
- but since we a strictly defined format the changelog is also machine parsable to include the changes in the installer or release notification

## 9. Deployment

### 9.1. Responsibility Boundary

Deployment is the stage between build artifacts and installation.

```text
Repository
    │
    ▼
  Build
    │
    ├── Development artifact
    ├── Test artifact
    └── Release artifact
             │
             ▼
        Deployment
             │
             ▼
     Artifact repository
             │
             ▼
        Installation
             │
             ▼
     ComputerCraft computer
```

The responsibilities are deliberately separated:

- **Build** transforms source code into a build artifact.
- **Deployment** makes a build artifact available at a distribution location.
- **Installation** retrieves an available artifact and installs it onto a ComputerCraft computer.

The deployment system does not define installer behavior.

### 9.2. Deployment Concepts

> \[!NOTE]
> Method and build\_type are independent configuration values. The system MUST NOT require them to have the same value.

#### Deployment Method

The deployment method identifies which build artifact type is being deployed:

- **Development** — mutable and replaceable.
- **Release** — versioned and immutable once successfully deployed.

Test artifacts are not deployable.

#### Deployment Destination

A deployment target identifies where an artifact is published.

Initial targets are:

- `local_filesystem`
- `git_repository`

The deployment method and deployment target are independent dimensions. All combinations of Development/Release with the two initial targets are valid.

### 9.3. Deployment Operation

A deployment operation handles exactly one build artifact and one deployment destination.

When several targets are selected, the deployment orchestrator creates independent operations. A failed deployment stops only that operation. It does not roll back or cancel other targets, which continue to be processed and are reported independently.

### 9.4. Release Deployment

The general Release sequence is:

```text
Clean source worktree
        │
        ▼
Build Release artifact
        │
        ▼
Run selected tests
        │
        ▼
Validate version/changelog
        │
        ▼
Prepare deployment target
        │
        ▼
Check existing version
        │
        ├── complete → error
        │
        └── incomplete → remove
        │
        ▼
Publish artifact
        │
        ▼
Update changelog
        │
        ▼
Commit changelog
```

The build occurs before the changelog is finalized:

```text
Commit A
   │
   ├── Build Release
   │       SOURCE_REVISION = A
   │
   ├── Deploy Release
   │
   └── Commit changelog → Commit B
```

If the final changelog commit fails, the already deployed Release remains deployed. No rollback is attempted.

### 9.5. Local Filesystem Destination

The `local_filesystem` target publishes the artifact directly to a configured filesystem location.

Development deployments are mutable and replace the existing Development artifact.

Release deployments are versioned and immutable:

```text
<project>/<target>/<version>/
```

If a Release directory contains `metadata.lua`, it is considered complete and deployment fails.

If the directory exists without `metadata.lua`, it is considered incomplete and may be removed and replaced.

### 9.6. Git Repository Destination

Git deployment uses a dedicated deployment branch and a separate local deployment workspace.

Before every deployment, the workspace is synchronized to the remote:

```text
git fetch remote
       │
       ▼
git reset --hard remote/deployment_branch
       │
       ▼
git clean -fd
       │
       ▼
clean deployment workspace
```

This ensures tracked modifications and untracked files from previous unsuccessful deployment attempts cannot affect the next deployment.

The deployment layout is:

```text
root/
├── project1/
│   ├── default/
│   │   ├── v1.0.0/
│   │   ├── v1.0.1/
│   │   └── ...
│   └── plugin1/
│       └── v1.0.0/
└── project2/
    └── default/
        └── v1.0.0/
```

This corresponds to:

```text
<project>/<build-target>/<version>/
```

The Git Release workflow is:

```text
fetch remote
    │
    ▼
reset --hard remote/deployment_branch
    │
    ▼
clean untracked files
    │
    ▼
inspect release directory
    │
    ├── metadata.lua exists → completed release → error
    │
    └── metadata.lua missing → incomplete release → remove
    │
    ▼
create directory structure
    │
    ▼
copy artifact files
    │
    ▼
create Git commit
    │
    ▼
push commit to remote
```

`metadata.lua` is the completion marker. It is made available only after the other artifact files have been prepared.

If deployment fails before the commit is pushed, the next attempt starts from the remote branch again and discards the failed local state. If a deployment was successfully pushed, the next attempt sees the actual remote state and can determine whether the release is already complete.

### 9.7. Artifact Metadata

Build artifacts contain `metadata.lua`, including the `FILES` manifest with artifact-relative paths and SHA-256 checksums.

Deployment publishes the artifact produced by the build and does not regenerate its build metadata.

For Release deployment, the presence of `metadata.lua` at the destination also serves as the deployment completion marker.

### 9.8. Failure Isolation

Deployment is fault tolerant across targets, but not within an individual target operation.

```text
Selected targets
      │
      ├── local filesystem
      │       └── failure → stop this deployment
      │
      ├── Git repository A
      │       └── success
      │
      └── Git repository B
              └── success
```

A failure at one target does not trigger rollback of another target.

### 9.9. Build and Test Integration

Deployment may orchestrate build and test execution but does not duplicate their responsibilities.

The normal Release pipeline is:

```text
Build → Test → Deployment
```

Build and test stages may be explicitly skipped by the deployment invocation. The deployment rules remain unchanged.

## 10. Installer

### 10.1. Boundary

The installer consumes deployed artifacts; it does not build source code.

```text
Repository -> Build -> Artifact -> Deployment -> Artifact Repository
                                                    |
                                                    v
                                               Root Installer
                                                    |
                                                    v
                                             ComputerCraft
```

### 10.2. Metadata model

The installer uses three persistent metadata layers.

#### 10.2.1 Root repository metadata

A root-level `metadata.lua` in a Git deployment repository is discovery data containing available programs, types, and versions.

```lua
return {
    programs = {
        {
            display_name = "Program 1",
            name = "program1",
            types = { "release", "development" },
            versions = { "2.0.0", "1.1.1", "1.1.0", "1.0.0" }
        }
    }
}
```

The root installer obtains this file from a configurable URL. It is discovery data; artifact metadata remains authoritative.

#### 10.2.2 Artifact metadata

Every artifact contains `metadata.lua`, including its `FILES` list and SHA-256 checksums.

```lua
return {
    NAME = "target_name",
    VERSION = "1.2.3",
    SOURCE_REVISION = "<full Git SHA>",
    BASE_URL = "<artifact directory URL>",
    FILES = {
        { path = "main.lua", sha256 = "<hash>" }
    }
}
```

It may additionally identify custom installer/uninstaller scripts and a dynamic-module repository.

#### 10.2.3 Installed-program metadata

The computer root contains hidden `.installed.lua`:

```lua
return {
    ["program1"] = {
        location = "/programs/program1",
        version = "1.0.0",
        displayName = "Program 1"
    }
}
```

The program installation contains another hidden `.installed.lua` for dynamic modules:

```lua
return {
    ["plugin1"] = {
        version = "1.0.1",
        displayName = "Plugin 1"
    }
}
```

### 10.3. Installation process

```text
Read root metadata
 -> select program/version/type
 -> download artifact metadata
 -> select installation location
 -> create registry entry without version
 -> download and verify files
 -> run custom installer
 -> optionally manage dynamic modules
 -> optionally configure startup
 -> write version to registry
```

The version is written only when installation is complete.

### 10.4. Interrupted installation

An incomplete installation has:

```lua
["program1"] = {
    location = "/programs/program1",
    displayName = "Program 1"
}
```

A subsequent installer run detects the missing version and offers retry, deletion, or continuation to normal management.

### 10.5. Update process

```text
Read installed program
 -> read old artifact metadata
 -> remove old FILES and old metadata.lua
 -> download new artifact metadata
 -> download and verify new FILES
 -> run custom installer with update indication
 -> update installed-program version
```

The old `FILES` list defines which artifact files the generic installer owns. Runtime/configuration files created after installation are outside that guarantee and require target-specific migration behavior.

### 10.6. Removal process

```text
Read installed program
 -> read artifact metadata
 -> run custom uninstaller
 -> delete FILES
 -> delete artifact metadata
 -> remove dynamic-module registry
 -> remove program registry entry
```

### 10.7. Dynamic modules

Dynamic modules are separate from immutable artifacts. If artifact metadata identifies a mutable module repository, the installer can query it and provide install/update/remove operations.

The per-program module registry is stored inside the program installation (`.installed.lua`). It records only modules installed for that program.

### 10.8. Startup

The root installer manages one startup integration. The two independent choices are:

- update before startup.
- add program to startup;

Possible behavior:

```text
startup disabled: no modification
startup enabled: program
startup + auto-update: installer update -> program
```

An existing startup file requires explicit user confirmation before replacement.

### 10.9. Deployment relationship

Git deployment publishes artifacts under:

```text
<project>/<build-target>/<version>/<type>
```

and maintains the root discovery metadata. Artifact metadata is the authoritative per-artifact manifest; root metadata is the mutable discovery registry.

### 10.11. Error handling

Errors are written for the user and therefore should provide useful data for the user. Error code can be included as additional information but should not be the main focus.

Error messages should easily convey the reason for the error and list possible solutions.

## 11. CLI

### 11.1. Command Layer

Parses and validates:

command
selector
filters

and creates an internal command request.

### 11.2. Selection Layer

Resolves the selector, applies command-specific filters, sorts the resulting entries alphabetically, and returns the concrete selection.

```txt
Selector
   ↓
Initial source-unit set
   ↓
Command filters
   ↓
Concrete selection
   ↓
Alphabetical ordering
```

The selection layer does not execute operations.

### 11.3. Selection Presentation

The CLI displays the complete selection before execution.

Example:

```txt
Selection:
  project1 / default
  project1 / plugin-a
  project2 / default
```

For an empty selection:

```txt
Selection:
  No entries matched the selector and filters.

Nothing to execute.
Check that the selector and filters are defined as expected.
```

### 11.4. Operation Layer

Receives the already-resolved selection and executes one operation per entry sequentially.

```txt
operation(selection[1])
operation(selection[2])
...
operation(selection[n])
```

### 11.5. Result Collection and Summary

Each operation produces an individual result. The CLI retains these results and produces a final summary without hiding individual failures.

Example:

```txt
Build summary:
  project1 / default   ✓
  project1 / plugin-a ✓
  project2 / default  ✗

Result:
  2 builds successful
  1 build failed
```

### 11.6. Build Flow

```txt
cc build <selector> [filters]
        ↓
   resolve selection
        ↓
   sort alphabetically
        ↓
   display selection
        ↓
   build each target sequentially
        ↓
   display build summary
```

Defaults:

```txt
type   = development
target = default
```

### 11.7. Test Flow

```txt
cc test <selector> [filters]
        ↓
   resolve Build Targets
        ↓
   apply test filter
        ↓
   sort selection
        ↓
   display selection
        ↓
   execute tests sequentially
        ↓
   display test summary
```

### 11.8. Deploy Flow

```txt
cc deploy <selector> [--deployment-target <name>]
        ↓
   resolve source selection
        ↓
   resolve Deployment Target
        ↓
   display selection
        ↓
   execute deployments sequentially
        ↓
   display deployment summary
```

The Deployment Target supplies method, destination, and build type.

### 11.9. Verify Flow

```txt
cc verify <selector> [filters]
        ↓
   resolve selected workflow
        ↓
   display selection/workflow
        ↓
   perform dry-run operations
        ↓
   display verify summary
```

Verification does not perform the side effects of the corresponding workflow.

### 11.10. Examples

```bash
# Default Development build
cc build project1

# Release build
cc build project1 --type release

# Build matching targets
cc build project1 --target plugin-*

# Build all libraries
cc build lib.all

# Run tests
cc test project1

# Run selected tests
cc test project1 --test-filter "TestMath.testAdd:TestString.*"

# Run everything except slow tests
cc test project1 --test-filter "-*.testSlow"

# Deploy using the default Deployment Target
cc deploy project1

# Deploy using a named Deployment Target
cc deploy project1 --deployment-target release-git

# Verify a Release build
cc verify project1 --build-type release

# Verify a deployment workflow
cc verify project1 --deployment-target release-git
```
