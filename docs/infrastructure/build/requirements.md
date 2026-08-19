# Requirements — Dependency Management and Build & Artifact Management

**Document status:** Draft — partial  
**Scope:** Functional and non-functional requirements currently derived from the defined user stories for Dependency Management and Build & Artifact Management.  
**Last updated:** 2026-08-19

> This document intentionally contains only requirements established so far. It is not yet a complete specification.

## 0.1 Terminology and Conformance Language

Normative text describes one or both of the following kinds of elements:

- Vital elements of the specification.
- Elements that contain the conformance language key words as defined by IETF RFC 2119, “Key words for use in RFCs to Indicate Requirement Levels”.

Informative text is potentially helpful to the user, but dispensable. Informative text can be changed, added, or deleted editorially without negatively affecting the implementation of the specification. Informative text does not contain conformance keywords.

All text in this document is, by default, normative.

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** in this document are to be interpreted as described in IETF RFC 2119.

According to: https://datatracker.ietf.org/doc/rfc2119/

## 0.2 Controlled Terminology

The following terms are provisionally defined and MUST be used consistently throughout the requirements, design, implementation, and user documentation.

| Term | Definition |
|---|---|
| **Project** | A logical unit of source code and build configuration within the repository. A project may represent an application, library, plugin, or another independently managed component. |
| **Build Target** | A user-defined configuration describing one independently buildable artifact. |
| **Build Type** | A predefined mode controlling how a build target is processed. The initial build types are Development, Test, and Release. |
| **Entry Point** | The source file from which static dependency resolution starts for a build target. |
| **Test Entry Point** | An optional alternative entry point used when building a target with the Test build type. |
| **Build Group** | A named selection of build targets that can be built together. |
| **Dependency** | A component required by another component for building or execution. |
| **Dependency Type** | The classification determining how a dependency participates in building and deployment. |
| **Build Configuration** | The configuration describing a project's build targets, dependencies, groups, and other build-related behavior. |
| **Build Artifact** | The logical output produced by building one build target. An artifact MAY contain multiple files. |
| **Preserved File** | A file included in an artifact but explicitly excluded from bundling and minification. |
| **Plugin** | An independently buildable, runtime-discoverable component that extends an application without being bundled into its main artifact. |
| **Plugin Registry** | A simple list or catalog describing plugins available to an application or project. |
| **Dynamic Dependency** | A dependency whose module identity cannot be determined statically and is resolved at runtime. |
| **Static Dependency** | A dependency whose module identity can be determined during build-time dependency resolution. |
| **Public API** | The modules or interfaces of a library intended for use by other components. |
| **Internal Module** | An implementation module that is not part of a library's public API. |
| **Build Pipeline** | The ordered processing stages used to transform source code into a build artifact. |
| **Source Revision** | The repository revision from which a build artifact was generated. |
| **Application Version** | The user-facing version identifying a particular independently releasable application. |
| **Plugin Version** | The user-facing version identifying a particular independently releasable plugin. |

This terminology list is expected to grow as additional system concepts are defined.

---

# 1. Dependency Management

## 1.1 Dependency Declaration

| ID | Requirement |
|---|---|
| FR-DM-001 | Each project or library that has dependencies MUST declare those dependencies in its build configuration. |
| FR-DM-002 | The build configuration MUST describe the dependency graph that is allowed for the project or library. |
| FR-DM-003 | `require()` statements MUST describe actual source-code usage of modules; they MUST NOT replace explicit dependency declarations. |
| FR-DM-004 | The build system MUST distinguish between declared dependencies and dependencies actually referenced by source code. |

### Principle

> **The project configuration describes the dependency graph; `require()` statements describe dependency usage.**

## 1.2 Dependency Validation

| ID | Requirement |
|---|---|
| FR-DM-005 | The build system MUST report a warning when a dependency is declared but is not used by the relevant source tree. |
| FR-DM-006 | The build system MUST report an error when statically resolvable source code uses a dependency that has not been declared. |
| FR-DM-007 | Dependency diagnostics MUST identify the affected dependency and the source/configuration location relevant to the problem. |
| FR-DM-008 | Dependency diagnostics SHOULD provide actionable information describing how the problem can be corrected. |
| FR-DM-009 | Dependency diagnostics MUST be distinguishable from build, bundling, minification, deployment, and other error categories. |

## 1.3 Dependency Resolution

| ID | Requirement |
|---|---|
| FR-DM-010 | The build system MUST resolve transitive dependencies of declared libraries. |
| FR-DM-011 | A dependency reached through multiple dependency paths MUST be resolved and included only once in a resulting artifact. |
| FR-DM-012 | The build system MUST distinguish application-local modules, project libraries, and external source libraries during module resolution. |
| FR-DM-013 | A project MUST NOT implicitly acquire another project's application-local modules as dependencies merely because they exist in the repository. |
| FR-DM-014 | Libraries SHOULD expose their intended public interface through a defined public module where practical. |
| FR-DM-015 | Library internal implementation modules SHOULD NOT be treated as part of the library's public API unless explicitly exposed by the library. |

## 1.4 Dynamic Dependencies and Plugins

| ID | Requirement |
|---|---|
| FR-DM-016 | The build system MUST distinguish statically resolvable module references from dynamically resolved module references. |
| FR-DM-017 | A dynamically resolved module reference MUST NOT be automatically resolved as a normal build-time dependency. |
| FR-DM-018 | The build system MUST emit a diagnostic when it encounters a dynamic module reference that cannot be resolved at build time. |
| FR-DM-019 | Dynamic module references MUST remain available for runtime resolution. |
| FR-DM-020 | The build system MUST support independently buildable plugin components that are not bundled into the main application artifact. |
| FR-DM-021 | A plugin MUST be buildable independently from the main application. |
| FR-DM-022 | The system MUST support a simple plugin registry describing plugins available for runtime discovery. |
| FR-DM-023 | The plugin registry MUST NOT require the build system to resolve every available plugin as a dependency of the main application. |

## 1.5 Version and Revision Handling

| ID | Requirement |
|---|---|
| FR-DM-024 | Project-local libraries MUST NOT require independent package-version management for normal dependency resolution. |
| FR-DM-025 | A build artifact MUST be traceable to the repository source revision from which it was generated. |
| FR-DM-026 | Independently releasable applications SHOULD have an explicit application version. |
| FR-DM-027 | Independently releasable plugins SHOULD have an explicit plugin version. |
| FR-DM-028 | Application and plugin versions MUST NOT replace repository source revisions as the mechanism for reproducing an exact source state. |

## 1.6 Dependency Graph Inspection

| ID | Requirement |
|---|---|
| FR-DM-029 | The build system MUST provide a mechanism to inspect the resolved dependency graph. |
| FR-DM-030 | Dependency graph output SHOULD be suitable for consumption by documentation tooling. |
| FR-DM-031 | The dependency graph representation SHOULD support generation of a visual representation such as a Mermaid graph. |

---

# 2. Build & Artifact Management

## 2.1 Build Targets

| ID | Requirement |
|---|---|
| FR-BA-001 | A project MUST be able to define multiple build targets. |
| FR-BA-002 | Each build target MUST have a unique name within its project. |
| FR-BA-003 | Each build target MUST define an entry point. |
| FR-BA-004 | The entry point MUST serve as the root of static dependency resolution for the target. |
| FR-BA-005 | A build target MAY define additional source files or modules required by its build process. |
| FR-BA-006 | Each build target MUST produce one logical build artifact. |
| FR-BA-007 | A build artifact MAY contain multiple output files. |
| FR-BA-008 | Each build target MUST have a stable identity that can be used by the build system and associated tooling. |

## 2.2 Build Types

| ID | Requirement |
|---|---|
| FR-BA-009 | Each build target MUST support the predefined Development, Test, and Release build types. |
| FR-BA-010 | Development builds MUST be available without requiring target-specific test or release configuration. |
| FR-BA-011 | Test builds MUST be available without requiring a test entry point; when no test entry point is configured, the normal entry point MAY be used. |
| FR-BA-012 | A target MAY define a separate test entry point for Test builds. |
| FR-BA-013 | Development builds MUST NOT minify application source code by default. |
| FR-BA-014 | Test builds MUST use release-like bundling and minification behavior by default. |
| FR-BA-015 | Release builds MUST use release-oriented bundling and minification behavior by default. |

## 2.3 Bundling and Minification

| ID | Requirement |
|---|---|
| FR-BA-016 | The default bundling behavior MUST bundle the target entry point and its statically resolved bundled dependencies into a single main program where technically possible. |
| FR-BA-017 | The build configuration MUST allow specific files or modules to be excluded from the main bundle. |
| FR-BA-018 | Release-oriented builds MUST minify bundled source code. |
| FR-BA-019 | Release-oriented builds SHOULD remove comments and other unnecessary source representation where doing so reduces artifact size without changing program behavior. |
| FR-BA-020 | The build system MUST preserve the functional distinction between bundled source and files explicitly excluded from bundling. |

## 2.4 Preserved Files

| ID | Requirement |
|---|---|
| FR-BA-021 | A build target MUST be able to define preserved files. |
| FR-BA-022 | Preserved files MUST be included in the resulting artifact without being bundled into the main program. |
| FR-BA-023 | Preserved files MUST NOT be minified by the normal target bundling/minification process. |
| FR-BA-024 | Preserved files SHOULD be suitable for user modification after deployment. |
| FR-BA-025 | Preserved-file configuration MUST be target-specific. |

## 2.5 Build Groups and Selection Scopes

| ID | Requirement |
|---|---|
| FR-BA-026 | Build targets MUST be assignable to user-defined build groups. |
| FR-BA-027 | A build group MUST represent a selectable collection of build targets. |
| FR-BA-028 | The build system MUST support building an individual build target. |
| FR-BA-029 | The build system MUST support building all build targets belonging to a project. |
| FR-BA-030 | The build system MUST support building all build targets belonging to a user-defined build group. |
| FR-BA-031 | The build system MUST support building all applicable build targets in the repository. |
| FR-BA-032 | Project-wide and repository-wide build selection MUST NOT require the user to manually create groups containing every applicable target. |

## 2.6 Build Pipeline

| ID | Requirement |
|---|---|
| FR-BA-033 | The build process MUST consist of clearly defined processing stages. |
| FR-BA-034 | Dependency resolution MUST occur before dependency-dependent bundling decisions are made. |
| FR-BA-035 | Dependency validation MUST occur before producing an artifact that depends on the validated dependency graph. |
| FR-BA-036 | Bundling MUST operate only on components selected for inclusion in the artifact. |
| FR-BA-037 | Minification MUST operate only on source selected for minification. |
| FR-BA-038 | Artifact creation MUST combine the generated bundled output with applicable preserved/generated files. |

## 2.7 Incremental Builds

| ID | Requirement |
|---|---|
| FR-BA-039 | The build system SHOULD detect when source inputs relevant to a target have not changed. |
| FR-BA-040 | The build system SHOULD detect changes to build configuration that affect a target's output. |
| FR-BA-041 | The build system SHOULD detect changes to relevant dependencies using dependency relationships and source metadata. |
| FR-BA-042 | When only one dependency branch changes, the build system SHOULD avoid rebuilding unrelated dependency branches. |
| FR-BA-043 | The incremental build mechanism SHOULD be based on deterministic input metadata such as file hashes and dependency relationships. |
| FR-BA-044 | The build system MAY cache intermediate build results to support efficient incremental rebuilding. |

## 2.8 Build Failure Handling

| ID | Requirement |
|---|---|
| FR-BA-045 | A failure in one independent build target MUST NOT prevent unrelated build targets from being attempted. |
| FR-BA-046 | A dependency failure MUST prevent targets that require the failed dependency from producing a successful artifact. |
| FR-BA-047 | Independent dependency branches SHOULD continue to be processed after an error in another branch. |
| FR-BA-048 | The build system MUST report informational messages, warnings, and errors as processing progresses. |
| FR-BA-049 | After completing all possible build work, the build system MUST provide a summary of successful, failed, and skipped work. |
| FR-BA-050 | The final build summary MUST include all errors and warnings encountered during the build operation. |

## 2.9 Build Output

| ID | Requirement |
|---|---|
| FR-BA-051 | Generated build artifacts MUST be distinguishable from source files. |
| FR-BA-052 | The build output SHOULD provide sufficient metadata to identify the project, target, build type, and source revision associated with an artifact. |
| FR-BA-053 | The build system SHOULD keep generated build output separate from editable project source. |

---

# 3. Non-Functional Requirements Established So Far

These requirements apply across both areas.

| ID | Requirement |
|---|---|
| NFR-001 | The build and dependency system SHOULD prioritize simplicity over features that are not required by current use cases. |
| NFR-002 | The system MUST provide deterministic dependency resolution for a given repository state and build configuration. |
| NFR-003 | Diagnostics SHOULD be actionable and SHOULD identify the category, location, cause, and possible remediation of a problem where practical. |
| NFR-004 | Build processing SHOULD maximize useful work in a single invocation rather than terminating at the first independent error. |
| NFR-005 | Terminology defined in the controlled terminology section MUST be used consistently throughout the system documentation, design, implementation, and user-facing interfaces. |
| NFR-006 | The build system SHOULD minimize generated artifact size because ComputerCraft environments have limited storage capacity. |
| NFR-007 | Build functionality SHOULD be structured into separable stages so that individual responsibilities remain understandable and testable. |

---

## 4. Explicitly Deferred Decisions

The following topics have been identified but are intentionally not yet specified:

- Exact build configuration file format and syntax.
- Exact build output directory structure.
- Exact incremental-build cache representation.
- Whether intermediate bundled/minified modules are cached and in which form.
- Exact static-analysis/parser implementation for detecting dynamic `require()` calls.
- Exact application/plugin registry format.
- Installer architecture and installer metadata.
- Deployment behavior.
- CLI commands and command-line interface design.
- Exact application/plugin versioning scheme.
- CI/release pipeline integration.
