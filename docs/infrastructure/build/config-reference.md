# Build and Test System Configuration Reference Sheet

This document serves as a comprehensive developer-facing reference sheet for the configuration system of the system build, test, and deployment pipeline.

---

## 1. Configuration Levels and Hierarchy

Configuration settings in the repository flow downward through a five-stage inheritance chain. Values defined at lower levels inherit, merge, or override those defined at higher levels:

```text
Repository Root (/) 
-> Category Root (/projects/) 
-> Package Root (/projects/my_project/) 
-> Build Target 
-> Build Type
```

1. **Repository Level**: Defined in `/build_config.yaml` at the root of the workspace. Configures global search paths, prefixes, and repository-wide default settings.
2. **Category Level**: Defined at the root of category folders (e.g., `/projects/build_config.yaml`, `/libraries/build_config.yaml`, `/external/build_config.yaml`) to set shared defaults for all packages under that category.
3. **Package/Project Level**: Defined inside the individual package folder (e.g., `build_config.yaml` for large packages or `<name>.build_config.yaml` sidecar configuration for small packages).
4. **Build Target Level**: Configured inside the package's `targets` map.
5. **Build Type Level**: Configured inside target-specific `development`, `test`, or `release` maps.

---

## 2. Configuration Key Catalog

Below is the complete catalog of all valid configuration keys, organized by logical domain.

### 2.1. Infrastructure and Versioning Keys

#### `artifact_base_url`

- **Level of Definition**: Repository Level Only
- **Data Type**: String (URL format)
- **Default Value**: None
- **Description**: Sets the root base URL where compiled release artifacts are hosted. Used in the compiled executable metadata manifest (`metadata.lua`) to enable individual file verification and remote downloads.
- **Example**:

  ```yaml
  artifact_base_url: "https://raw.githubusercontent.com/username/repository/main/build/"
  ```

#### `version`

- **Level of Definition**: Build Target Level Only
- **Data Type**: String (Must adhere strictly to Semantic Versioning regex)
- **Allowed Pattern**: `^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?$`
- **Description**: Specifies the semantic version of the target's output artifact. Highly critical for the update and installer subsystems to manage compatibility. Mandatory for `release` builds, and generates a warning if omitted in `development` or `test` builds.
- **Example**:

  ```yaml
  version: "1.4.0-beta.2"
  ```

---

### 2.2. Build Definition and Structural Keys

#### `targets`

- **Level of Definition**: Package/Project Level
- **Data Type**: Object/Map (Keys are custom target names; values are target configurations)
- **Allowed Pattern for Target Names**: `^[A-Za-z0-9](?:[A-Za-z0-9_]*[A-Za-z0-9])?$` (Alphanumeric and underscores; cannot start or end with underscores); Need to be unique inside a project
- **Description**: Declares the map of independently buildable targets in the project. If a project contains no `targets` key, the build system implicitly constructs a single `default` target using the folder name as the artifact name.
- **Example**:

  ```yaml
  targets:
    default:
      entry_point: "main.lua"
    cli_tool:
      entry_point: "cli.lua"
      version: "1.0.0"
  ```

#### `display_name`

- **Level of Definition**: Build Target Level Only
- **Data Type**: String
- **Description**: Specifies the name is displayed to the user inside the installer.
- **Example**:

  ```yaml
  name: "My super cool Program"
  ```

#### `entry_point`

- **Level of Definition**: All levels (Repository, Category, Package, Target, Build Type)
- **Data Type**: String (File path relative to the active source or test source root)
- **Description**: The main entry file from which static dependency resolution starts. Will trigger an error if the specified file does not exist at compile time.
- **Example**:

  ```yaml
  entry_point: "init.lua"
  ```

#### `dependencies`

- **Level of Definition**: All levels (Repository, Category, Package, Target, Build Type)
- **Data Type**: List of strings (Or a Structured List Map for merging)
- **Description**: Lists the names of required repository source packages (libraries or external modules). An unprefixed name searches the libraries directory first, then external. Explicit category prefixes like `lib.` and `external.` bypass discovery and select the category directly. URLs and arbitrary absolute/external paths are forbidden.
- **Example**:

  ```yaml
  dependencies:
    - "lib.logging"
    - "external.json"
  ```

#### `preserved`

- **Level of Definition**: All levels (Repository, Category, Package, Target, Build Type)
- **Data Type**: List of strings (Or a Structured List Map for merging)
- **Description**: Specifies files, subdirectories, or glob patterns relative to the active source root that must be excluded from bundling and minification. Preserved modules and their transitive closures are copied to the artifact as individual, unminified files while keeping their logical structures intact.
- **Example**:

  ```yaml
  preserved:
    - "config/default.json"
    - "plugins/*.lua"
    - "module/moduleb/"
  ```

#### `groups`

- **Level of Definition**: Build Target Level Only
- **Data Type**: List of strings
- **Allowed Pattern for Group Names**: `^[A-Za-z0-9](?:[A-Za-z0-9_]*[A-Za-z0-9])?$`
- **Description**: Assigns the target to one or more user-defined build groups to facilitate batch building (e.g., building all components in a group using CLI options).
- **Example**:

  ```yaml
  groups:
    - "plugins"
    - "utilities"
  ```

#### `installer_path`

- **Level of Definition**: Build Target Level Only
- **Data Type**: String (File path relative to the active source)
- **Description**: The path to a custom installer. The installer is invoked after the root installer has successfully downloaded all required files.
- **Example**:

  ```yaml
  installer_path: "installer.lua"
  ```

#### `uninstaller_path`

- **Level of Definition**: Build Target Level Only
- **Data Type**: String (File path relative to the active source)
- **Description**: The path to a custom uninstaller. The uninstaller is invoked before the root installer deletes all artifact files.
- **Example**:

  ```yaml
  uninstaller_path: "uninstaller.lua"
  ```

---

### 2.3. Build Profiles (Types)

#### `development` / `test` / `release`

- **Level of Definition**: Build Target Level
- **Data Type**: Object
- **Description**: Defines build-type-specific configurations (such as overriding `entry_point` or adding extra `dependencies`).
- **Example**:

  ```yaml
  development:
    dependencies:
      - "lib.debug_tools"
  ```

---

### 2.4. Directory Layout and Namespace Keys (Path Settings)

All path settings can be defined at any level (usually defined globally at the repository level).

#### `source_root`

- **Level of Definition**: All levels
- **Data Type**: String (Directory path relative to the package root)
- **Default Value**: `"src/"`
- **Constraint**: The build system automatically appends a trailing slash `/` if omitted.
- **Description**: Specifies the folder containing the package's production source code. Used as the base path for module resolution and the root directory for `entry_point` and `preserved` relative definitions.
- **Example**:

  ```yaml
  source_root: "sources/"
  ```

#### `test_source_root`

- **Level of Definition**: All levels
- **Data Type**: String (Directory path relative to the package root)
- **Default Value**: `"test/"`
- **Constraint**: Automatically appends a trailing slash `/` if omitted.
- **Description**: Directory containing automated test suites (`Test*.lua` files) and test environments.
- **Example**:

  ```yaml
  test_source_root: "specs/"
  ```

#### `project_search_path`

- **Level of Definition**: All levels
- **Data Type**: String (Directory path relative to the repository root)
- **Default Value**: `"./"`
- **Constraint**: Automatically appends a trailing slash `/` if omitted.
- **Description**: Path where projects and application packages reside.
- **Example**:

  ```yaml
  project_search_path: "applications/"
  ```

#### `library_search_path`

- **Level of Definition**: All levels
- **Data Type**: String (Directory path relative to the repository root)
- **Default Value**: `"libraries/"`
- **Constraint**: Automatically appends a trailing slash `/` if omitted.
- **Description**: Category-level folder where shared libraries are located.
- **Example**:

  ```yaml
  library_search_path: "shared/lib/"
  ```

#### `external_search_path`

- **Level of Definition**: All levels
- **Data Type**: String (Directory path relative to the repository root)
- **Default Value**: `"external/"`
- **Constraint**: Automatically appends a trailing slash `/` if omitted.
- **Description**: Category-level folder where third-party or vendored dependencies reside.
- **Example**:

  ```yaml
  external_search_path: "vendored/"
  ```

#### `dynamic_dependency_install_path`

- **Level of Definition**: All levels
- **Data Type**: String (Directory path relative to the active source root)
- **Default Value**: `"plugins/"`
- **Constraint**: Automatically appends a trailing slash `/` if omitted.
- **Description**: Defines the default directory where dynamically loaded packages/plugins must be placed or installed.
- **Example**:

  ```yaml
  dynamic_dependency_install_path: "addons/"
  ```

#### `project_prefix`

- **Level of Definition**: All levels
- **Data Type**: String
- **Default Value**: `""` (Empty string)
- **Constraint**: Automatically appends a trailing dot `.` if omitted.
- **Description**: The prefix prepended to project module names in import statements.
- **Example**:

  ```yaml
  project_prefix: "app"
  ```

#### `library_prefix`

- **Level of Definition**: All levels
- **Data Type**: String
- **Default Value**: `"lib."`
- **Constraint**: Automatically appends a trailing dot `.` if omitted.
- **Description**: Prefix used for requiring shared libraries.
- **Example**:

  ```yaml
  library_prefix: "shared"
  ```

#### `external_prefix`

- **Level of Definition**: All levels
- **Data Type**: String
- **Default Value**: `"external."`
- **Constraint**: Automatically appends a trailing dot `.` if omitted.
- **Description**: Prefix used for requiring external vendored code.
- **Example**:

  ```yaml
  external_prefix: "vendor"
  ```

#### `test_prefix`

- **Level of Definition**: All levels
- **Data Type**: String
- **Default Value**: `"test."`
- **Constraint**: Automatically appends a trailing dot `.` if omitted.
- **Description**: Namespace prepended to dynamically discovered test suites to separate them from production code.
- **Example**:

  ```yaml
  test_prefix: "spec"
  ```

### 2.5 Deployment

#### `deployments`

- **Level of Definition**: Repository Root, Category Root, Package Root and/ or Build Target
- **Data Type**: Object/Map (Keys are custom target names; values are target configurations)
- **Allowed Pattern for Target Names**: `^[A-Za-z0-9](?:[A-Za-z0-9_]*[A-Za-z0-9])?$` (Alphanumeric and underscores; cannot start or end with underscores)
- **Description**: Declares the map of independently deployable targets in the repository/ category, package, build target.
- **Example**

```yaml
deployments:
  release_git:
    method: release
    destination: git_repository
    build_type: release
  local: 
    method: development
    destination: local_filesystem
    build_type: development
```

#### `method`

- **Level of Definition**: Deployment target only
- **Data Type**: String
- **Allowed options**: "development", "release"
- **Description**: Defines which workflow should be used to deploy the artefact.
- **Example**:

```yaml
method: development
```

#### `destination`

- **Level of Definition**: Deployment target only
- **Data Type**: Object/ Map
- **Allowed options**: "local_filesystem", "git_repository" (defined by `name` field)
- **Description**: The location where the artefact should be deployed to.

##### `local_filesystem`

- **Level of Definition**: Deployment Destination only
- **Data Type**: Object/ Map
- **Parameters**:
  - **name**: always `local_filesystem`
  - **path**: string (path to a local directory)
  - **mode**: string (optional); `copy` (copy files to destination), `link` (create soft links at destination) (default: copy)
- **Description**: Deploy the artifact directly to a git repository
- **Example**:

```yaml
destination: 
  name: git_repository
  path: /Users/max/Library/Application Support/PrismLauncher/instances/create-astral/
  mode: copy
  branch: releases
```

##### `git_repository`

- **Level of Definition**: Deployment Destination only
- **Data Type**: Object/ Map
- **Parameters**:
  - **name**: always `git_repository`
  - **url**: string (url to a git repository)
  - **branch**: string (optional); any valid branch name in the repository (default: main)
- **Description**: Deploy the artifact directly to a git repository
- **Example**:

```yaml
destination: 
  name: git_repository
  url: git@github.com:KuerbisKuchen02/CC-ME-System.git
  branch: releases
```

#### `build_type`

- **Level of Definition**: Deployment target only
- **Data Type**: String
- **Allowed options**: "development", "release"
- **Description**: Defines which artefact should be used for the deployment
- **Example**:

```yaml
build_type: development
```

---

## 3. Configuration Inheritance and List-Merging Mechanics

### 3.1. General Merging Rules

- **Scalars**: Lower-level values entirely override higher-level inherited values (e.g., a target-level `entry_point` overrides a package-level default).
- **Maps**: Merged key-by-key. If a key collision occurs, the more-specific lower-level key overrides the inherited key.
- **Lists**: By default, list-based configuration keys (`dependencies`, `preserved`) inherit by extending (appending) the parent items.

### 3.2. Structured List-Merging Modes

To allow developers to clear or replace inherited lists (also applies to deployment targets) rather than appending to them, the configuration system supports a structured map syntax using the `mode` attribute:

#### Append Mode (Default)

Appends lower-level list items to the inherited list. Using a raw YAML list acts as an implicit append.

```yaml
# Equivalent to: preserved: [ "config/default.json" ]
preserved:
  mode: append
  items:
    - "config/default.json"
```

#### Replace Mode

Discard all inherited list values and replace them completely with the newly specified list.

```yaml
preserved:
  mode: replace
  items:
    - "config/local_only.json"
```

#### Clear Mode

Completely wipes the inherited list, resulting in an empty list. No `items` block is needed.

```yaml
preserved:
  mode: clear
```

---

## 4. Path Interpretation Rules

Path configurations are strictly parsed based on their starting characters to resolve their final location:

1. **`./` (Leading dot-slash)**: Path is relative to the active source root (or test source root) of the current target.
2. **`/` (Leading slash)**: Path is absolute relative to the repository root.
3. **No leading character**: Path is relative to the active source root (or test source root) of the current target.

---

## 5. End-to-End Configuration Example

Below is a complete, illustrative example showcasing how settings are inherited, overridden, and merged at various levels of the configuration hierarchy.

### 5.1. Repository Level (`/build_config.yaml`)

```yaml
# Global search roots and prefixes
library_search_path: "libraries/"
external_search_path: "external/"
project_search_path: "projects/"

library_prefix: "lib."
external_prefix: "external."
project_prefix: ""

# Root default for source roots and installers
source_root: "src/"
test_source_root: "test/"
artifact_base_url: "https://raw.githubusercontent.com/username/repository/main/build/"

# Global default entry point and dependencies
entry_point: "main.lua"
dependencies:
  - "lib.logging"

deployments:
  release_git:
    method: release
    destination: git_repository
    build_type: release
  local: 
    method: development
    destination: local_filesystem
    build_type: development
```

### 5.2. Category Level (`/projects/build_config.yaml`)

```yaml
# Category override: All projects must preserve their layout-related configs
preserved:
  - "config/default.json"
```

### 5.3. Package/Project Level (`/projects/my_app/build_config.yaml`)

```yaml
# App-specific configuration merging with category and repository values
dependencies:
  mode: append
  items:
    - "external.json"

targets:
  # Implicitly maps to artifact folder names as build/my_app/artifacts/my_app/
  default:
    version: "1.0.0"
    entry_point: "init.lua"  # Overrides repository 'main.lua'

  # A target with its own custom compiled executable name (build/my_app/artifacts/standalone-cli/)
  standalone-cli:
    version: "1.0.0"
    entry_point: "cli.lua"
    groups:
      - "utilities"
    preserved:
      mode: replace  # Replaces category-inherited 'config/default.json'
      items:
        - "config/cli-defaults.json"

    # Build type overrides
    development:
      dependencies:
        - "lib.debug_tools"  # Only imported during dev builds

    release:
      preserved:
        mode: clear  # Release build removes all separate files for bundling\n

  deployments:
    mode: replace
    release_git:
      method: release
      destination: git_repository
      build_type: development
```
