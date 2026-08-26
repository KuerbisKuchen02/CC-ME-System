# Requirements - Build, Test and Deployment system

**Document status:** Draft — partial  
**Scope:** Functional and non-functional requirements currently derived from the defined [user stories](/docs/infrastructure/build/user_stories.md)
**Last updated:** 2026-08-23

# 0 Terminology and Conformance Language

## 0.1 Conformance Language

Normative text describes one or both of the following kinds of elements:

- Vital elements of the specification.
- Elements that contain the conformance language key words as defined by IETF RFC 2119, “Key words for use in RFCs to Indicate Requirement Levels”.

Informative text is potentially helpful to the user, but dispensable. Informative text can be changed, added, or deleted editorially without negatively affecting the implementation of the specification. Informative text does not contain conformance keywords.

All text in this document is, by default, normative.

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** in this document are to be interpreted as described in IETF RFC 2119.

According to: [rfc2119](https://datatracker.ietf.org/doc/rfc2119/)

## 0.2 Controlled Terminology

ID structure: `<type>-<scope>-<topic_number><number>`.

Example `FR-DEP-102`: Second functional requirement from the scope Dependency Management topic 1 (dependency declaration).

Types:

- `FR` = Functional Requirement
- `NFR` = Not Functional Requirement

Scopes:

- `XFN` = Cross functional (no specific scope)
- `CFG` = Build Configuration
- `DEP` = Dependency Management
- `BLD` = Build and Artifact Management
- `TST` = Software Testing.

---

# 1 Cross Functional

| ID        | Requirement                                                                                                                               | Reference                       | Dependency |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- | ---------- |
| FR-XFN-01 | The build system MUST support managing and building multiple projects within one repository.                                              | US-XFN-01                       |            |
| FR-XFN-02 | A build artifact MUST be traceable to the repository source revision from which it was generated.                                         | US-DEP-15                       |            |
| FR-XFN-03 | Independently releasable applications SHOULD have an explicit application version.                                                        | US-DEP-14                       |            |
| FR-XFN-04 | Application and plugin versions MUST NOT replace repository source revisions as the mechanism for reproducing an exact source state.      | US-DEP-13, US-DEP-14, US-DEP-15 |            |
| FR-XFN-06 | The build system diagnostics MUST clearly identify the diagnostic category, affected project/target/module, and cause.                    | US-DEP-18                       |            |
| FR-XFN-07 | Each build system component/ stage MUST use consistent naming conventions and use unique diagnostic codes.                                | US-DEP-18                       |            |
| FR-XFN-08 | A build performed from a specific repository revision MUST resolve in-repository dependencies from that same revision.                    | US-DEP-15                       |            |

---

# 2 Build Configuration

| ID        | Requirement                                                                                                                                                                                                                                      | Reference            | Dependency |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------- | ---------- |
| FR-CFG-01 | The default repository structure MUST distinguish `projects/`, `libraries/`, and `external/` source categories.                                                                                                                                  | US-BLD-01            |            |
| FR-CFG-02 | By default, project source modules MUST be located below `projects/<project>/src/`.                                                                                                                                                              | US-BLD-01            |            |
| FR-CFG-03 | A shared library MUST be either `libraries/<name>.lua` or a directory package below `libraries/<name>/src/`.                                                                                                                                     | US-BLD-01            |            |
| FR-CFG-04 | By default, external source modules MUST be located below `external/`.                                                                                                                                                                           | US-BLD-01            |            |
| FR-CFG-05 | Repository-level configuration MUST allow the library and external category roots to be overridden.                                                                                                                                              | US-BLD-02            |            |
| FR-CFG-06 | The default logical module prefixes MUST be `lib` for shared libraries, `external` for external code, and `test` for test modules.                                                                                                               | US-BLD-02            |            |
| FR-CFG-07 | Module prefixes and the project `source_root` and `test_source_root` MUST be configurable.                                                                                                                                                       | US-BLD-02            |            |
| FR-CFG-08 | The build configuration MUST allow specific files or modules to be excluded from the main bundle.                                                                                                                                                | US-BLD-15            |            |
| FR-CFG-09 | Build configuration MUST support inheritance in the order repository, category, package/project, target, and build type. Scalars MUST override inherited values and maps MUST merge by key with the more-specific value winning.                 | US-BLD-17            |            |
| FR-CFG-10 | A project, large library, or large external package configuration MUST be named `build_config.yaml` and reside at that entity's root. A configurable small package MUST use the sidecar form `<name>.build_config.yaml`.                         | US-DEP-02            |            |
| FR-CFG-11 | The category configurations `projects/build_config.yaml`, `libraries/build_config.yaml`, and `external/build_config.yaml` MUST apply to entries in their respective categories.                                                                  | US-BLD-17            |            |
| FR-CFG-12 | Inherited list values MUST append by default. A list configuration MAY use `mode: replace` with `items` to replace inherited values, or `mode: clear` without items to clear them.                                                               | US-BLD-17            |            |
| FR-CFG-13 | Project build targets MUST be defined as entries of a `targets` map. Target, project, and group names MUST match `^[A-Za-z0-9](?:[A-Za-z0-9_]*[A-Za-z0-9])?$`.                                                                                   | US-BLD-05, US-BLD-24 |            |
| FR-CFG-14 | If a project has no explicit targets, the system MUST create an implicit `default` target. A library or external package without targets MUST be treated as a manifest and MUST NOT produce an artifact.                                         | US-BLD-05, US-DEP-01 |            |
| FR-CFG-15 | `entry_point` and `preserved` values MUST be interpreted relative to the applicable source root. Unknown or invalid configuration fields MUST be reported as warnings and ignored; duplicate targets and invalid required values MUST be errors. | US-BLD-05, US-BLD-16 |            |
| FR-CFG-16 | A target version MUST be a Semantic Versioning value. It MUST be required for Release builds and SHOULD produce a warning when absent from Development or Test builds.                                                                           | US-DEP-13, US-DEP-14 |            |
| FR-CFG-17 | `artifact_base_url` MUST be configurable only at repository level.                                                                                                                                                                               | US-DEP-15            |            |

---

# 3 Dependency Management

Topics:

1. Dependency Declaration
2. Dependency Validation
3. Dependency Resolution
4. Dynamic Dependencies and Plugins
5. Dependency Graph Inspection

## 3.1 Dependency Declaration

| ID         | Requirement                                                                                                                                                                                                             | Reference            | Dependency |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------- |
| FR-DEP-101 | The build system MUST support shared libraries that can be consumed by multiple projects.                                                                                                                               | US-DEP-01            |            |
| FR-DEP-102 | Each project or library that has dependencies MUST declare those dependencies in its build configuration.                                                                                                               | US-DEP-02            |            |
| FR-DEP-103 | The build configuration MUST describe the dependency graph, while `require()` statements MUST describe module usage.                                                                                                    | US-DEP-02            |            |
| FR-DEP-104 | The build system MUST distinguish between declared dependencies and dependencies actually referenced by source code.                                                                                                    | US-DEP-03            |            |
| FR-DEP-105 | The build system MUST distinguish static and dynamic dependencies.                                                                                                                                                      | US-DEP-07            |            |
| FR-DEP-106 | Static dependencies MUST use `require()` statement with string literals for the module name.                                                                                                                            | US-DEP-07            |            |
| FR-DEP-107 | Dynamic dependencies MUST NOT use `require()` statement with string literals for the module name                                                                                                                        | US-DEP-08            |            |
| FR-DEP-108 | Dependencies MUST be source packages within the repository's `libraries/` or `external/` category; arbitrary filesystem paths and URLs MUST NOT be dependency declarations.                                             | US-DEP-20            |            |
| FR-DEP-109 | A dependency declaration MUST name a complete package. An unprefixed name MUST search libraries before external packages; `lib.` and `external.` prefixes MUST select their category explicitly.                        | US-DEP-02            |            |
| FR-DEP-110 | A single-file package without configuration MUST NOT contain static dependencies. A package that contains static dependencies MUST declare them in its applicable configuration.                                        | US-DEP-02, US-DEP-04 |            |
| FR-DEP-111 | An `init.lua` module MUST define the public interface of its package subtree. Callers outside that package MUST NOT require descendants of that interface; callers inside the package MAY require its internal modules. | US-DEP-16            |            |

## 3.2 Dependency Validation

| ID         | Requirement                                                                                                                 | Reference | Dependency |
| ---------- | --------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-DEP-205 | The build system MUST report a warning when a dependency is declared but is not used by the relevant source tree.           | US-DEP-03 |            |
| FR-DEP-206 | The build system MUST report an error when statically resolvable source code uses a dependency that has not been declared.  | US-DEP-04 |            |
| FR-DEP-207 | Dependency diagnostics MUST identify the affected dependency and the source/configuration location relevant to the problem. | US-DEP-18 |            |
| FR-DEP-208 | Dependency diagnostics SHOULD provide actionable information describing how the problem can be corrected.                   | US-DEP-18 |            |
| FR-DEP-209 | Dependency diagnostics MUST be distinguishable from build, bundling, minification, deployment, and other error categories.  | US-DEP-18 |            |

## 3.3 Dependency Resolution

| ID         | Requirement                                                                                                                                                                                                                     | Reference            | Dependency |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------- |
| FR-DEP-301 | The build system MUST resolve transitive dependencies of declared libraries.                                                                                                                                                    | US-DEP-05            |            |
| FR-DEP-302 | When multiple modules require the same static dependency, the bundler MUST include the dependency only once in a bundled artifact.                                                                                              | US-DEP-17            |            |
| FR-DEP-303 | The build system MUST distinguish application-local modules, project libraries, and external source libraries during module resolution.                                                                                         | US-BLD-04            |            |
| FR-DEP-304 | Dependencies MUST support target-level scope and build-type-level scope. Target-level dependencies MUST be available to all build types of the target; build-type-level dependencies MUST only be available to that build type. | US-DEP-06            |            |
| FR-DEP-305 | Static dependencies MUST be eligible for dependency resolution and bundling according to the selected build type.                                                                                                               | US-DEP-07            |            |
| FR-DEP-306 | Dynamic dependencies MUST NOT be statically resolved or bundled into the referencing artifact.                                                                                                                                  | US-DEP-08            |            |
| FR-DEP-307 | A `require()` whose argument is a string literal MUST be treated as statically resolvable, while a `require()` whose argument is not a string literal MUST be treated as dynamic.                                               | US-DEP-07, US-DEP-09 |            |
| FR-DEP-308 | Dependency resolution MUST start at the configured entry point of the current build target. The system then MUST recursively search all required modules for dependencies.                                                      | US-DEP-05            |            |
| FR-DEP-309 | The resolver MUST report a static dependency cycle as an error and identify the cycle.                                                                                                                                          | US-DEP-18            |            |
| FR-DEP-310 | A same-name single-file and directory package within a category MUST be rejected because it maps to the same logical module identity.                                                                                           | US-BLD-04            |            |

## 3.4 Dynamic Dependencies and Plugins

| ID         | Requirement                                                                                                                      | Reference | Dependency |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-DEP-401 | Dynamic module references MUST remain available for runtime resolution.                                                          | US-DEP-08 |            |
| FR-DEP-402 | The build system MUST support independently buildable plugin components that are not bundled into the main application artifact. | US-DEP-11 |            |
| FR-DEP-403 | A plugin MUST be buildable independently from the main application.                                                              | US-DEP-12 |            |
| FR-DEP-404 | The system MUST support a simple plugin registry describing plugins available for runtime discovery.                             | US-DEP-10 |            |
| FR-DEP-405 | The plugin registry MUST NOT require the build system to resolve every available plugin as a dependency of the main application. | US-DEP-10 |            |

## 3.5 Dependency Graph Inspection

| ID         | Requirement                                                                                                                                                                                                                                           | Reference | Dependency |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-DEP-501 | The build system MUST provide a mechanism to inspect the resolved dependency graph.                                                                                                                                                                   | US-DEP-19 |            |
| FR-DEP-502 | Dependency graph output SHOULD be suitable for consumption by documentation tooling.                                                                                                                                                                  | US-DEP-19 |            |
| FR-DEP-503 | The dependency graph representation SHOULD support generation of a visual representation such as a Mermaid graph.                                                                                                                                     | US-DEP-19 |            |

## 3.6. Module Mapping

| ID         | Requirement                                                                                                                                                                                                                                           | Reference | Dependency |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-DEP-601 | The build system MUST treat the logical module name as the module's identity and MUST NOT require the logical module name to equal its repository path.                                                                                               | US-BLD-03 |            |
| FR-DEP-602 | For project modules, the default logical module name MUST be derived from the configured project module source root and the configured prefix.                                                                                                        | US-BLD-03 |            |
| FR-DEP-603 | For shared-library modules, the default logical module name MUST be derived from the configured library source root and the configured prefix.                                                                                                        | US-BLD-04 |            |
| FR-DEP-604 | For external modules, the default logical module name MUST be derived from the configured external source root and the configured prefix.                                                                                                             | US-BLD-04 |            |
| FR-DEP-605 | The development tooling SHOULD expose the build system's module mappings to Lua Language Server. If Lua Language Server cannot resolve the mappings through generated/configured workspace information, source annotations MAY be used as a fallback. | US-BLD-18 |            |
| FR-DEP-606 | Test modules MUST derive their module name from `test_source_root` and `test_prefix`, and MUST be emitted below the corresponding test namespace in an unbundled artifact.                                                                            | US-TST-02 |            |

---

# 4 Build & Artifact Management

Topics:

1. Build Targets
2. Build Types
3. Bundling and Minification
4. Preserved Files
5. Build Groups and Selection Scopes
6. Build Pipeline
7. Incremental Builds
8. Build Failure Handling
9. Build Output

## 4.1 Build Targets

| ID         | Requirement                                                                                                                                           | Reference | Dependency |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-BLD-101 | A project MUST be able to define multiple build targets.                                                                                              | US-BLD-06 |            |
| FR-BLD-102 | Each build target MUST have a unique name within its project.                                                                                         | US-BLD-05 |            |
| FR-BLD-103 | Each artifact-producing build target MUST have an effective entry point. A library or external package manifest without targets MUST NOT require one. | US-BLD-05 |            |
| FR-BLD-104 | The entry point MUST serve as the root of static dependency resolution for the target.                                                                | US-BLD-05 |            |
| FR-BLD-105 | A build target MAY define additional source files or modules required by its build process.                                                           | US-BLD-05 |            |
| FR-BLD-106 | Each build target MUST produce one logical build artifact.                                                                                            | US-BLD-09 |            |
| FR-BLD-107 | A build artifact MAY contain multiple output files.                                                                                                   | US-BLD-10 |            |
| FR-BLD-108 | Each build target MUST have a stable identity that can be used by the build system and associated tooling.                                            | US-BLD-24 |            |

## 4.2 Build Types

| ID         | Requirement                                                                                                                                                                                         | Reference            | Dependency |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------- |
| FR-BLD-201 | Each build target MUST support the predefined Development, Test, and Release build types.                                                                                                           | US-BLD-07            |            |
| FR-BLD-202 | Development builds MUST be available without requiring target-specific test or release configuration.                                                                                               | US-BLD-07            |            |
| FR-BLD-203 | Test builds MUST discover `Test*.lua` suites below `test_source_root` and use every discovered suite together with the test environment/effective test entry point as a dependency-resolution root. | US-BLD-08, US-TST-02 |            |
| FR-BLD-204 | A target MAY define a separate test entry point for Test builds.                                                                                                                                    | US-BLD-08            |            |

## 4.3 Bundling and Minification

| ID         | Requirement                                                                                                                                                          | Reference | Dependency |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-BLD-301 | The bundling process MUST bundle the target entry point and its statically resolved bundled dependencies into a single main program where technically possible.      | US-BLD-15 |            |
| FR-BLD-302 | Minifying SHOULD remove comments and other unnecessary source representation where doing so reduces artifact size without changing program behavior.                 | US-BLD-15 |            |
| FR-BLD-303 | The build system MUST preserve the functional distinction between bundled source and files explicitly excluded from bundling.                                        | US-BLD-15 |            |
| FR-BLD-304 | When a module is bundled into the main artifact, its individual `require()` statement MUST be resolved at build time and replaced with the source code of the module | US-BLD-15 |            |

## 4.4 Preserved Files

| ID         | Requirement                                                                                                                                                                                                | Reference | Dependency |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-BLD-401 | A build target MUST be able to define preserved files.                                                                                                                                                     | US-BLD-16 |            |
| FR-BLD-402 | Preserved files MUST be included in the resulting artifact without being bundled into the main program.                                                                                                    | US-BLD-16 |            |
| FR-BLD-403 | Preserved files MUST NOT be minified by the normal target bundling/minification process.                                                                                                                   | US-BLD-16 |            |
| FR-BLD-404 | Preserved files SHOULD be suitable for user modification after deployment.                                                                                                                                 | US-BLD-16 |            |
| FR-BLD-405 | Preserved-file configuration MUST be target-specific.                                                                                                                                                      | US-BLD-16 |            |
| FR-BLD-406 | The build system MUST NOT rewrite `require()` statements belonging to preserved files.                                                                                                                     | US-BLD-16 |            |
| FR-BLD-407 | A preserved module and its complete static runtime dependency closure MUST be emitted as files. If a module is both preserved and otherwise eligible for bundling, it MUST be emitted as a preserved file. | US-BLD-16 |            |

## 4.5 Build Groups and Selection Scopes

| ID         | Requirement                                                                                                                              | Reference | Dependency |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-BLD-501 | Build targets MUST be assignable to user-defined build groups.                                                                           | US-BLD-11 |            |
| FR-BLD-502 | A build group MUST represent a selectable collection of build targets.                                                                   | US-BLD-11 |            |
| FR-BLD-503 | The build system MUST support building an individual build target.                                                                       | US-BLD-12 |            |
| FR-BLD-504 | The build system MUST support building all build targets belonging to a project.                                                         | US-BLD-12 |            |
| FR-BLD-505 | The build system MUST support building all build targets belonging to a user-defined build group.                                        | US-BLD-12 |            |
| FR-BLD-506 | The build system MUST support building all applicable build targets in the repository.                                                   | US-BLD-12 |            |
| FR-BLD-507 | Project-wide and repository-wide build selection MUST NOT require the user to manually create groups containing every applicable target. | US-BLD-12 |            |

## 4.6 Build Pipeline

| ID         | Requirement                                                                                                   | Reference | Dependency |
| ---------- | ------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-BLD-601 | The build process MUST consist of clearly defined processing stages.                                          | US-BLD-19 |            |
| FR-BLD-602 | Dependency resolution MUST occur before dependency-dependent bundling decisions are made.                     | US-BLD-19 |            |
| FR-BLD-603 | Dependency validation MUST occur before producing an artifact that depends on the validated dependency graph. | US-BLD-19 |            |
| FR-BLD-604 | Bundling MUST operate only on components selected for inclusion in the artifact.                              | US-BLD-19 |            |
| FR-BLD-605 | Minification MUST operate only on source selected for minification.                                           | US-BLD-19 |            |
| FR-BLD-606 | Artifact creation MUST combine the generated bundled output with applicable preserved/generated files.        | US-BLD-19 |            |

## 4.7 Incremental Builds

| ID         | Requirement                                                                                                                                           | Reference            | Dependency |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------- |
| FR-BLD-701 | The build system MUST record deterministic hashes for source files relevant to a target so it can determine whether the artifact requires rebuilding. | US-BLD-20            |            |
| FR-BLD-702 | Full incremental and intermediate-result caching are deferred; the initial implementation MUST NOT require them.                                      | US-BLD-20, US-BLD-21 |            |

## 4.8 Build Failure Handling

| ID         | Requirement                                                                                                                | Reference | Dependency |
| ---------- | -------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-BLD-801 | A failure in one independent build target MUST NOT prevent unrelated build targets from being attempted.                   | US-BLD-22 |            |
| FR-BLD-802 | A dependency failure MUST prevent targets that require the failed dependency from producing a successful artifact.         | US-BLD-22 |            |
| FR-BLD-803 | Independent dependency branches SHOULD continue to be processed after an error in another branch.                          | US-BLD-22 |            |
| FR-BLD-804 | The build system MUST report informational messages, warnings, and errors as processing progresses.                        | US-BLD-23 |            |
| FR-BLD-805 | After completing all possible build work, the build system MUST provide a summary of successful, failed, and skipped work. | US-BLD-23 |            |
| FR-BLD-806 | The final build summary MUST include all errors and warnings encountered during the build operation.                       | US-BLD-23 |            |

## 4.9 Build Output

| ID         | Requirement                                                                                                                                                                                                | Reference            | Dependency |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------- |
| FR-BLD-901 | Unbundled artifact paths MUST correspond to the logical module hierarchy so that statically resolved `require()` calls remain valid without changing their module names.                                   | US-BLD-13            |            |
| FR-BLD-902 | Development artifacts MUST emit only the static dependency closure of the effective normal entry point as unbundled, unminified modules.                                                                   | US-BLD-14            |            |
| FR-BLD-903 | Test artifacts MUST emit the combined static dependency closure of the discovered suites and test roots as unbundled, unminified modules.                                                                  | US-BLD-25            |            |
| FR-BLD-904 | Release artifacts MUST bundle all eligible static modules into a single main Lua artifact.                                                                                                                 | US-BLD-15            |            |
| FR-BLD-905 | Release artifacts MUST minify the bundled main Lua artifact.                                                                                                                                               | US-BLD-15            |            |
| FR-BLD-906 | Every artifact MUST contain metadata identifying its name, target, build type, source revision, optional version, artifact base URL, and a `FILES` list of artifact-relative paths with SHA-256 checksums. | US-BLD-24, US-DEP-15 |            |
| FR-BLD-907 | The build system SHOULD keep generated build output separate from editable project source.                                                                                                                 | US-BLD-01            |            |
| FR-BLD-908 | Preserved files MUST retain their relative directory structure below the applicable project's `src/` directory in unbundled/deployed output.                                                               | US-BLD-16            |            |
| FR-BLD-909 | Artifacts MUST be written below `build/<project>/artifacts/<artifact-name>/<build-type>/`, and rebuilding locally MAY overwrite that artifact directory.                                                   | US-BLD-24            |            |
| FR-BLD-910 | A Release build MUST require a clean worktree, configured repository-level `artifact_base_url`, full source commit SHA, and effective target version.                                                      | US-DEP-15            |            |

---

# 5 Testing

Topics:

1. Test Suite Structure and Discovery
2. Test Lifecycle and Failure Handling
3. Test Execution and Assertions
4. Test Reporting and Observability
5. Repository-Level Test Execution
6. Test Environment and Artifacts
7. Test Quality Attributes

## 5.1 Test Suite Structure and Discovery

| ID         | Requirement                                                                                                                                                          | Reference | Dependency |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-TST-101 | The test framework MUST organize tests into test suites represented by classes inheriting from a generic test-suite base class.                                      | US-TST-01 |            |
| FR-TST-102 | A Lua file whose name matches `Test*.lua` and which returns a class inheriting from the generic test-suite base class MUST be recognized as a test suite.            | US-TST-02 |            |
| FR-TST-103 | Each discovered test file MUST contain exactly one test suite.                                                                                                       | US-TST-02 |            |
| FR-TST-104 | Test cases MUST be discovered automatically from test-suite methods whose names begin with `test`. No explicit test registration or decorator mechanism is required. | US-TST-03 |            |

## 5.2 Test Lifecycle and Failure Handling

| ID         | Requirement                                                                                                                                                                                                                                                                                                                                                                                                                         | Reference | Dependency |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-TST-201 | Each test suite MUST execute using a fresh test-suite instance. Class members MAY be used as shared fixture state for the test cases in that suite.                                                                                                                                                                                                                                                                                 | US-TST-04 |            |
| FR-TST-202 | `setup()` MUST be executed before every test case in the suite.                                                                                                                                                                                                                                                                                                                                                                     | US-TST-05 |            |
| FR-TST-203 | `teardown()` MUST be executed after every test case in the suite.                                                                                                                                                                                                                                                                                                                                                                   | US-TST-05 |            |
| FR-TST-204 | `setupTestSuite()` MUST be executed before the first test case of the suite.                                                                                                                                                                                                                                                                                                                                                        | US-TST-05 |            |
| FR-TST-205 | `teardownTestSuite()` MUST be executed after the last test case of the suite.                                                                                                                                                                                                                                                                                                                                                       | US-TST-05 |            |
| FR-TST-206 | The test runner MUST provide environment setup and environment teardown around the complete test execution.                                                                                                                                                                                                                                                                                                                         | US-TST-05 |            |
| FR-TST-207 | A `setup()` failure MUST fail its test case and prevent that test method from executing. A `teardown()` failure MUST fail its test case even if the test method passed. A `setupTestSuite()` failure MUST cause all test cases in the affected suite to fail or not execute, while allowing the runner to continue with the next suite. A `teardownTestSuite()` failure MUST cause the suite to fail even if all test cases passed. | US-TST-10 |            |
| FR-TST-208 | Test methods, lifecycle methods, and runner operations MUST be executed using protected calls so that failures do not terminate the complete test run.                                                                                                                                                                                                                                                                              | US-TST-10 |            |

## 5.3 Test Execution and Assertions

| ID         | Requirement                                                                                                                                                    | Reference | Dependency |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-TST-301 | The framework MUST provide `assertTrue`, `assertFalse`, `assertEquals`, `assertNotEquals`, `assertNil`, `assertThrows`, `assertDeepEquals`, and `assertDelta`. | US-TST-06 |            |
| FR-TST-302 | Test suites and test cases MUST execute in alphabetical order by default.                                                                                      | US-TST-07 |            |
| FR-TST-303 | The test runner MUST support an optional shuffle mode that randomizes test execution order.                                                                    | US-TST-08 |            |
| FR-TST-304 | A shuffled test run MUST use and report an explicit seed so that the exact execution order of a failed randomized run can be reproduced.                       | US-TST-09 |            |

## 5.4 Test Reporting and Observability

| ID         | Requirement                                                                                                                                        | Reference | Dependency |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-TST-401 | The test framework MUST provide a mechanism to register callbacks or listeners for environment, suite, and test-case lifecycle events.             | US-TST-11 |            |
| FR-TST-402 | Failures in test listeners MUST be isolated and MUST NOT terminate or otherwise invalidate the test execution itself.                              | US-TST-12 |            |
| FR-TST-403 | A test method whose name begins with `DISABLED_` MUST be reported as `SKIPPED` and MUST NOT be executed.                                           | US-TST-13 |            |
| FR-TST-404 | A test suite whose name begins with `DISABLED_` MUST be reported as skipped and its test cases MUST NOT be executed.                               | US-TST-13 |            |
| FR-TST-405 | Every test case MUST result in exactly one of `PASS`, `FAIL`, or `SKIPPED`.                                                                        | US-TST-14 |            |
| FR-TST-406 | A failed test case MUST report the project, test suite, test case, and reason for failure.                                                         | US-TST-14 |            |
| FR-TST-407 | The test runner MUST report test results during execution and MUST provide a final summary containing counts of passed, failed, and skipped tests. | US-TST-15 |            |

## 5.5 Repository-Level Test Execution

| ID         | Requirement                                                                                                                                          | Reference | Dependency |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-TST-501 | The build system MUST provide a repository-level test runner capable of discovering and executing test-enabled projects.                             | US-TST-16 |            |
| FR-TST-502 | The repository-level test runner MUST support selecting projects using the same build-group concept used for repository and project build selection. | US-TST-16 |            |
| FR-TST-503 | Each project MUST be executed using a fresh test-runner instance so that project-level test state does not leak between projects.                    | US-TST-16 |            |
| FR-TST-504 | If any test case in a suite fails, the complete suite MUST be considered failed.                                                                     | US-TST-17 |            |
| FR-TST-505 | If any suite in a project fails, the complete project MUST be considered failed.                                                                     | US-TST-17 |            |
| FR-TST-506 | If any project fails, the complete repository-level test run MUST be considered failed.                                                              | US-TST-17 |            |
| FR-TST-507 | The repository-level test runner MUST continue executing other suites and projects after failures whenever they can still be executed.               | US-TST-18 |            |
| FR-TST-508 | The repository-level test runner MUST report results for each project and then provide an overall repository result.                                 | US-TST-16 |            |

## 5.6 Test Environment and Artifacts

| ID         | Requirement                                                                                                 | Reference | Dependency |
| ---------- | ----------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| FR-TST-601 | The test build type MUST execute in the development environment rather than inside a ComputerCraft runtime. | US-TST-19 |            |
| FR-TST-602 | ComputerCraft APIs used by tests MUST be mocked or replaced by the test developer when required.            | US-TST-20 |            |
| FR-TST-603 | The test system MUST NOT require or prescribe a specific ComputerCraft API mocking framework.               | US-TST-20 |            |

## 5.7 Test Quality Attributes

| ID          | Requirement                                                                                                                                                   | Reference | Dependency |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| NFR-TST-701 | The test framework MUST NOT be responsible for isolating system resources such as the filesystem. Such isolation is the responsibility of the test developer. | US-TST-20 |            |

---

# 6 Non-Functional Requirements Established So Far

These requirements apply across both areas.

| ID     | Requirement                                                                                                                                                                  |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| NFR-01 | The build and dependency system SHOULD prioritize simplicity over features that are not required by current use cases.                                                       |
| NFR-02 | The system MUST provide deterministic dependency resolution for a given repository state and build configuration.                                                            |
| NFR-03 | Diagnostics SHOULD be actionable and SHOULD identify the category, location, cause, and possible remediation of a problem where practical.                                   |
| NFR-04 | Build processing SHOULD maximize useful work in a single invocation rather than terminating at the first independent error.                                                  |
| NFR-05 | Terminology defined in the controlled terminology section MUST be used consistently throughout the system documentation, design, implementation, and user-facing interfaces. |
| NFR-06 | The build system SHOULD minimize generated artifact size because ComputerCraft environments have limited storage capacity.                                                   |
| NFR-07 | Build functionality SHOULD be structured into separable stages so that individual responsibilities remain understandable and testable.                                       |
| NFR-08 | The default repository layout SHOULD require minimal configuration for normal projects and libraries.                                                                        |
