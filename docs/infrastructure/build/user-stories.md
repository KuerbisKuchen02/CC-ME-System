# User Stories — Dependency Management and Build & Artifact Management

**Document status:** Draft — partial  
**Scope:** User stories currently defined for Dependency Management and Build & Artifact Management.  
**Last updated:** 2026-08-19

> This document intentionally contains only the user stories established so far. Additional user stories will be added as the requirements analysis progresses.

## 1. Dependency Management

| ID | Title | User Story |
|---|---|---|
| US-DM-001 | Explicit project dependencies | As a developer, I want to explicitly declare the dependencies of an application or library in its build configuration, so that the dependency graph is deterministic and understandable. |
| US-DM-002 | Dependency usage validation | As a developer, I want the build system to compare declared dependencies with `require()` usage, so that the configured dependency graph reflects actual source-code usage. |
| US-DM-003 | Detect unused dependencies | As a developer, I want to be warned when a dependency is declared but not used, so that I can remove obsolete dependency declarations. |
| US-DM-004 | Detect undeclared dependencies | As a developer, I want the build system to report an error when source code uses an undeclared dependency, so that dependencies cannot be introduced accidentally. |
| US-DM-005 | Transitive dependencies | As a developer, I want dependencies of libraries to be resolved automatically, so that I do not have to manually declare every transitive dependency in an application. |
| US-DM-006 | Dependency deduplication | As a developer, I want dependencies that are reachable through multiple dependency paths to be included only once, so that artifacts remain as small as possible. |
| US-DM-007 | Public library interfaces | As a library developer, I want a library to be able to expose a defined public interface while hiding internal implementation modules, so that consumers do not need to depend on internal implementation details. |
| US-DM-008 | Dependency namespaces | As a developer, I want application-local modules, project libraries, and external source libraries to have distinguishable module namespaces, so that module ownership and resolution remain unambiguous. |
| US-DM-009 | Dependency diagnostics | As a developer, I want dependency errors and warnings to clearly identify their origin, location, cause, and possible remediation, so that dependency problems can be resolved efficiently. |
| US-DM-010 | Dependency graph inspection | As a developer, I want to inspect the resolved dependency graph, so that I can understand and debug the relationships between project components. |
| US-DM-011 | Dynamic module loading | As a developer, I want an application to load modules dynamically at runtime, so that optional functionality such as plugins can be selected without bundling all available modules into the main application. |
| US-DM-012 | Dynamic dependency diagnostics | As a developer, I want the build system to identify dynamically resolved module references, so that I am informed when a dependency cannot be resolved statically and will instead be resolved at runtime. |
| US-DM-013 | Plugin catalog | As a developer, I want to maintain a simple list of available plugins, so that an application can discover available runtime plugins. |
| US-DM-014 | Independent plugin artifacts | As a developer, I want plugins to be built as independent artifacts, so that they can be installed or updated without being bundled into the main application. |
| US-DM-015 | Selective plugin builds | As a developer, I want to build individual plugin targets independently, so that I do not need to rebuild unrelated application components. |
| US-DM-016 | Plugin versioning | As a developer, I want independently deployable plugins to have explicit versions, so that plugin compatibility can be managed independently from internal project libraries. |
| US-DM-017 | Application versioning | As a developer, I want independently identifiable applications to have their own versions, so that releases can identify which application changed even when multiple applications share one repository. |
| US-DM-018 | Source revision tracking | As a developer, I want build artifacts to record the repository revision from which they were built, so that released artifacts remain traceable and reproducible. |

## 2. Build & Artifact Management

| ID | Title | User Story |
|---|---|---|
| US-BA-001 | Define build targets | As a developer, I want to define named build targets with an entry point and build configuration, so that the build system knows what source belongs to an independently buildable artifact. |
| US-BA-002 | Multiple build targets | As a developer, I want a project to contain multiple build targets, so that applications, plugins, and other independently buildable components can coexist in one project. |
| US-BA-003 | Build types | As a developer, I want each build target to support predefined build types, so that the same target can be built for development, testing, or release without duplicating its configuration. |
| US-BA-004 | Test entry point | As a developer, I want a build target to optionally define a separate test entry point, so that tests can be built and executed independently of the normal application entry point. |
| US-BA-005 | Preserved files | As a developer, I want to mark files as preserved, so that they are included in an artifact without being bundled or minified and can remain user-editable after deployment. |
| US-BA-006 | Target-specific preserved files | As a developer, I want preserved-file definitions to belong to individual build targets, so that different artifacts can have different sets of user-maintained files. |
| US-BA-007 | One artifact per target | As a developer, I want each build target to produce one logical build artifact, so that the relationship between a target and its deployable output is unambiguous. |
| US-BA-008 | Multiple files in an artifact | As a developer, I want an artifact to contain multiple output files when required, so that preserved files and generated support files can accompany the main bundled program. |
| US-BA-009 | Build groups | As a developer, I want to assign build targets to named groups, so that related targets such as all plugins for an application can be built together. |
| US-BA-010 | Build selection scopes | As a developer, I want to build a single target, all targets in a project, a named group, or all targets in the repository, so that I can choose the appropriate build scope for my task. |
| US-BA-011 | Default bundling | As a developer, I want the build system to bundle the entry point and its statically resolved dependencies into a single main program by default, so that deployed applications use as little storage as practical. |
| US-BA-012 | Exclude modules/files from bundling | As a developer, I want to explicitly exclude selected files or modules from bundling, so that components such as configuration files or independently deployed modules can remain separate. |
| US-BA-013 | Minification | As a developer, I want release-oriented builds to minify bundled source code and remove unnecessary comments and whitespace, so that artifacts consume as little ComputerCraft storage as practical. |
| US-BA-014 | Development builds | As a developer, I want development builds to avoid minification, so that the resulting artifact remains convenient to inspect and debug. |
| US-BA-015 | Test builds | As a developer, I want test builds to use the test entry point when configured and apply release-like bundling/minification, so that the tested artifact closely represents the deployed program. |
| US-BA-016 | Build pipeline | As a developer, I want the build process to consist of clearly separated stages such as dependency resolution, validation, bundling, minification, and artifact creation, so that each stage has a clear responsibility and can report meaningful diagnostics. |
| US-BA-017 | Incremental builds | As a developer, I want the build system to detect unchanged source, configuration, and dependency inputs, so that unaffected components do not need to be rebuilt. |
| US-BA-018 | Dependency-aware incremental builds | As a developer, I want changes to a dependency to trigger rebuilding only of the affected dependent branches, so that large projects can be rebuilt efficiently. |
| US-BA-019 | Fault-tolerant builds | As a developer, I want independent targets and dependency branches to continue building when another branch fails, so that one build invocation reports as many independent problems as possible. |
| US-BA-020 | Build summary | As a developer, I want the build system to provide a final summary of successful targets, failures, errors, and warnings, so that I can quickly assess the overall result of a build operation. |
| US-BA-021 | Build target identity | As a developer, I want each build target to have a stable identity, so that targets can be referenced consistently by the build system, caching, diagnostics, and later deployment tooling. |
