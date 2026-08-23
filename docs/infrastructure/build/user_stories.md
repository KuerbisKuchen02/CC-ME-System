# User Stories - Build, Test and Deployment System

> **Document status:** Draft
>
> **Scope:** Consolidated user stories for dependency management, build and artifact management, and software testing.
>
> **Last updated:** 2026-08-23

ID structure: `US-<scope>-<number>`.

Scopes:

- `XFN` = Cross functional (no specific scope)
- `CFG` = Build Configuration
- `DEP` = Dependency Management
- `BLD` = Build and Artifact Management
- `TST` = Software Testing.

User-story structure: *As [persona], I want [software goal], so that [result].*

## Cross Functional

| ID        | Title             | User Story                                                                                                                                                                  | Derived   |
| --------- | ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| US-XFN-01 | Multiple projects | As a developer, I want to manage and build multiple projects in a single repository, so that related applications and components can share infrastructure and dependencies. | FR-XFN-01 |

## Dependency Management

| ID        | Title                           | User Story                                                                                                                                                                                                 | Derived                |
| --------- | ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| US-DEP-01 | Shared libraries                | As a developer, I want to create shared libraries that can be automatically included in projects, so that common functionality does not have to be duplicated.                                             | FR-DEP-101, FR-DEP-302 |
| US-DEP-02 | Explicit dependencies           | As a developer, I want to explicitly declare project and library dependencies in a build configuration, so that the intended dependency graph is clear and reproducible.                                   |                        |
| US-DEP-03 | Dependency usage validation     | As a developer, I want the build system to compare declared dependencies with actual static `require()` usage, so that unused declared dependencies are reported as warnings.                              |                        |
| US-DEP-04 | Undeclared dependencies         | As a developer, I want the build system to report an error when source code uses an undeclared dependency, so that dependencies cannot be introduced accidentally.                                         |                        |
| US-DEP-05 | Transitive dependencies         | As a developer, I want dependencies of libraries to be resolved automatically, so that I do not have to manually declare every transitive dependency in an application.                                    |                        |
| US-DEP-06 | Dependency scope                | As a developer, I want dependencies to be definable at target level and build-type level, so that development and test dependencies do not have to be included in release builds.                          |                        |
| US-DEP-07 | Static and dynamic dependencies | As a developer, I want to distinguish static dependencies from dynamic dependencies, so that statically resolvable modules can be included in an artifact while runtime-loaded modules remain separate.    |                        |
| US-DEP-08 | Dynamic dependencies            | As a developer, I want dynamic dependencies to be excluded from static dependency resolution, so that runtime plugin systems can load modules dynamically.                                                 |                        |
| US-DEP-09 | Dynamic dependency diagnostics  | As a developer, I want the build system to identify dynamically resolved module references, so that I am informed when a dependency cannot be resolved statically and will instead be resolved at runtime. |                        |
| US-DEP-10 | Plugin catalog                  | As a developer, I want to maintain a simple list of available plugins, so that an application can discover available runtime plugins.                                                                      |                        |
| US-DEP-11 | Independent plugin artifacts    | As a developer, I want independently buildable plugin components, so that plugins can be distributed, installed, and updated separately from their host project.                                           |                        |
| US-DEP-12 | Selective plugin builds         | As a developer, I want to build individual plugin targets independently, so that I do not need to rebuild unrelated application components.                                                                |                        |
| US-DEP-13 | Plugin versioning               | As a developer, I want independently deployable plugins to have explicit versions, so that plugin compatibility can be managed independently from internal project libraries.                              |                        |
| US-DEP-14 | Application versioning          | As a developer, I want independently identifiable applications to have their own versions, so that releases can identify which application changed even when multiple applications share one repository.   |                        |
| US-DEP-15 | Source revision tracking        | As a developer, I want build artifacts to record the repository revision from which they were built, so that released artifacts remain traceable and reproducible.                                         |                        |
| US-DEP-16 | Dependency encapsulation        | As a library developer, I want a library to expose a defined public interface while hiding internal implementation modules, so that consumers do not need to depend on internal implementation details.    |                        |
| US-DEP-17 | Dependency deduplication        | As a developer, I want shared dependencies to be included only once in a bundled artifact, so that artifacts remain as small as possible.                                                                  |                        |
| US-DEP-18 | Dependency diagnostics          | As a developer, I want dependency and linking errors to clearly identify what failed, where it failed, and how it can be addressed, so that dependency problems can be resolved efficiently.               |                        |
| US-DEP-19 | Dependency graph inspection     | As a developer, I want to inspect the resolved dependency graph, so that I can understand and debug dependency relationships.                                                                              |                        |
| US-DEP-20 | In-repository dependencies      | As a developer, I want project, shared-library, and external dependency source code to live inside the repository, so that dependency management remains simple and self-contained.                        |                        |

## Build and Artifact Management

| ID        | Title                               | User Story                                                                                                                                                                                                                                                     |
| --------- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| US-BLD-01 | Conventional repository structure   | As a developer, I want a conventional repository structure for projects, libraries, external code, documentation, build output, and infrastructure, so that I can work with minimal configuration.                                                             |
| US-BLD-02 | Configurable source roots           | As a developer, I want repository source roots and module prefixes to be configurable, so that I can adapt the build system when the conventional structure does not fit my project.                                                                           |
| US-BLD-03 | Logical module identity             | As a developer, I want modules to have stable logical names independent of their repository locations, so that repository organization and runtime layout can differ.                                                                                          |
| US-BLD-04 | Module namespaces                   | As a developer, I want project, shared-library, and external modules to have distinguishable namespaces, so that module ownership and resolution remain unambiguous.                                                                                           |
| US-BLD-05 | Define build targets                | As a developer, I want to define named build targets with an entry point and build configuration, so that the build system knows what source belongs to an independently buildable artifact.                                                                   |
| US-BLD-06 | Multiple build targets              | As a developer, I want a project to contain multiple build targets, so that applications, plugins, and other independently buildable components can coexist in one project.                                                                                    |
| US-BLD-07 | Build types                         | As a developer, I want each build target to support predefined build types, so that the same target can be built for development, testing, or release without duplicating its configuration.                                                                   |
| US-BLD-08 | Test entry point                    | As a developer, I want a build target to optionally define a separate test entry point, so that tests can be built and executed independently of the normal application entry point.                                                                           |
| US-BLD-09 | One artifact per target             | As a developer, I want each build target to produce one logical build artifact, so that the relationship between a target and its deployable output is unambiguous.                                                                                            |
| US-BLD-10 | Multiple files in an artifact       | As a developer, I want an artifact to contain multiple output files when required, so that preserved files and generated support files can accompany the main program.                                                                                         |
| US-BLD-11 | Build groups                        | As a developer, I want to assign build targets to named groups, so that related targets can be built together.                                                                                                                                                 |
| US-BLD-12 | Build selection scopes              | As a developer, I want to build a single target, all targets in a project, a named group, or all targets in the repository, so that I can choose the appropriate build scope for my task.                                                                      |
| US-BLD-13 | Artifact module layout              | As a developer, I want unbundled artifacts to preserve the logical module directory structure, so that `require()` calls remain valid without path rewriting.                                                                                                  |
| US-BLD-14 | Development artifacts               | As a developer, I want development artifacts to preserve the complete module structure without bundling or minification, so that the running program remains easy to inspect and debug.                                                                        |
| US-BLD-15 | Release artifacts                   | As a developer, I want release artifacts to bundle and minify the application into a single main Lua file, so that ComputerCraft storage constraints are respected.                                                                                            |
| US-BLD-16 | Preserved files                     | As a developer, I want to mark files as preserved, so that they are excluded from bundling and minification and remain available as separate files with their source-relative directory structure.                                                             |
| US-BLD-17 | Hierarchical configuration          | As a developer, I want repository, project/library, target, and build-type configuration to inherit from higher-level configuration, so that common defaults do not need to be repeated.                                                                       |
| US-BLD-18 | Lua Language Server integration     | As a developer, I want the development environment to understand the same logical module mappings as the build system, so that Lua Language Server completion and documentation work with shared and external modules.                                         |
| US-BLD-19 | Build pipeline                      | As a developer, I want the build process to consist of clearly separated stages such as dependency resolution, validation, bundling, minification, and artifact creation, so that each stage has a clear responsibility and can report meaningful diagnostics. |
| US-BLD-20 | Incremental builds                  | As a developer, I want the build system to detect unchanged source, configuration, and dependency inputs, so that unaffected components do not need to be rebuilt.                                                                                             |
| US-BLD-21 | Dependency-aware incremental builds | As a developer, I want changes to a dependency to trigger rebuilding only of the affected dependent branches, so that large projects can be rebuilt efficiently.                                                                                               |
| US-BLD-22 | Fault-tolerant builds               | As a developer, I want independent targets and dependency branches to continue building when another branch fails, so that one build invocation reports as many independent problems as possible.                                                              |
| US-BLD-23 | Build summary                       | As a developer, I want the build system to provide a final summary of successful targets, failures, errors, and warnings, so that I can quickly assess the overall result of a build operation.                                                                |
| US-BLD-24 | Build target identity               | As a developer, I want each build target to have a stable identity, so that targets can be referenced consistently by the build system, caching, diagnostics, and later deployment tooling.                                                                    |
| US-BLD-25 | Test Artifacts                      | As a developer, I want test artifacts to preserve the complete module structure without bundling or minification so that source file names and line numbers remain useful when diagnosing test failures.                                                       |

## Software Testing

| ID        | Title                          | User Story                                                                                                                                                                           |
| --------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| US-TST-01 | Test suites                    | As a developer, I want to organize tests into xUnit-style test suites, so that related test cases can share a fixture and lifecycle.                                                 |
| US-TST-02 | Automatic test discovery       | As a developer, I want test suites to be discovered automatically from `test*.lua` files, so that I do not need explicit test registration.                                          |
| US-TST-03 | Test case discovery            | As a developer, I want test cases to be discovered from methods beginning with `test`, so that adding a test does not require additional registration.                               |
| US-TST-04 | Test fixtures                  | As a developer, I want each test suite to have its own fixture object shared by its test cases, so that related tests can operate on common state.                                   |
| US-TST-05 | Test lifecycle                 | As a developer, I want setup and teardown methods at environment, suite, and test-case levels, so that I can prepare and clean up test state consistently.                           |
| US-TST-06 | Assertions                     | As a developer, I want a small, focused assertion API covering common equality, boolean, nil, exception, deep-table, and numeric-delta checks, so that tests remain simple.          |
| US-TST-07 | Deterministic execution        | As a developer, I want tests to execute in deterministic alphabetical order by default, so that failures are reproducible.                                                           |
| US-TST-08 | Randomized execution           | As a developer, I want an optional shuffle mode, so that hidden test-order dependencies can be detected.                                                                             |
| US-TST-09 | Reproducible shuffle           | As a developer, I want a randomized test run to report its seed, so that a failed shuffled run can be reproduced exactly.                                                            |
| US-TST-10 | Isolated test failures         | As a developer, I want failures in individual tests or lifecycle methods to be isolated, so that the remaining tests can continue executing.                                         |
| US-TST-11 | Test listeners                 | As a developer, I want to register test listeners for lifecycle events, so that I can implement reporting, monitoring, and result collection without changing test execution.        |
| US-TST-12 | Listener isolation             | As a developer, I want listener failures to be isolated, so that a broken reporter cannot terminate the test run.                                                                    |
| US-TST-13 | Disabled tests                 | As a developer, I want to disable test cases or complete suites using a `DISABLED_` prefix, so that disabled tests remain visible to the test runner.                                |
| US-TST-14 | Test results                   | As a developer, I want test cases to report `PASS`, `FAIL`, or `SKIPPED`, so that the result of every test is explicit.                                                              |
| US-TST-15 | Continuous reporting           | As a developer, I want test results to be printed during execution and summarized at the end, so that I receive immediate feedback and a complete overview.                          |
| US-TST-16 | Project test runner            | As a developer, I want to run the tests of multiple projects from a repository-level runner, so that I can verify the repository in one operation.                                   |
| US-TST-17 | Failure propagation            | As a developer, I want failures to propagate from test cases to suites, projects, and the repository result, so that the overall result accurately reflects all failures.            |
| US-TST-18 | Continue after project failure | As a developer, I want the repository test runner to continue with other projects after one project fails, so that a single run provides as much diagnostic information as possible. |
| US-TST-19 | ComputerCraft API mocking      | As a developer, I want test builds to execute outside ComputerCraft, so that tests can run quickly in the development environment.                                                   |
| US-TST-20 | Developer-controlled mocks     | As a developer, I want to provide or override ComputerCraft API implementations myself, so that the test system does not need to impose a mandatory mocking framework.               |
