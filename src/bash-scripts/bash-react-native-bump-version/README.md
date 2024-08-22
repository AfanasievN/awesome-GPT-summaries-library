Here’s a detailed `README` for your version bumping script, including examples, explanations, and usage instructions.

---

# Version Bumping Script

This script automates the process of versioning your React Native project, updating version numbers across iOS and Android platforms. It handles the following tasks:

- Updates the version in `package.json`.
- Updates the iOS project files, including `Info.plist` and `project.pbxproj`.
- Updates the Android project files, including `build.gradle`.

## Prerequisites

Ensure you have the following tools installed on your system:

- **Node.js**: For handling `package.json` version updates.
- **PlistBuddy**: For updating iOS plist files. (`PlistBuddy` is a command-line tool available on macOS by default).
- **sed**: A stream editor for filtering and transforming text.

## Usage

To use the script, navigate to the directory containing the script and run it with the appropriate options. Below is the general usage pattern.

### Command Structure

```sh
./bump_version.sh [--type major|minor|patch] [--semver version] [--skip-semver-for platform1,platform2] [--skip-code-for platform1,platform2]
```

### Options

- `--type [major|minor|patch]`: Specify the type of semantic version bump you want (`major`, `minor`, or `patch`). If provided, this option overrides `--semver`.

- `--semver version`: Directly specify the new semantic version (e.g., `1.2.3`). This option overrides `--type`.

- `--skip-semver-for [android|ios|all]`: Skip updating the semantic version for the specified platforms.

- `--skip-code-for [android|ios|all]`: Skip updating the build/version code for the specified platforms.

- `-h, --help`: Display usage information.

### Examples

#### 1. Bumping the Patch Version

```sh
./bump_version.sh --type patch
```

This command increments the patch version in `package.json`, `Info.plist`, and `build.gradle`. For example, it might update the version from `1.0.0` to `1.0.1`.

#### 2. Setting a Specific Version

```sh
./bump_version.sh --semver 2.1.0
```

This command sets the version across all platforms to `2.1.0`, without incrementing the current version.

#### 3. Skipping Version Updates for iOS

```sh
./bump_version.sh --type minor --skip-semver-for ios
```

This command increments the minor version for Android but skips updating the version for iOS.

#### 4. Skipping Build Code Updates for Both Platforms

```sh
./bump_version.sh --type minor --skip-code-for all
```

This command increments the minor version but does not update the build codes for either platform.

## How It Works

### 1. Updating `package.json`

The script first updates the version in `package.json` based on the provided options. It either increments the version using the `--type` option or sets it directly using the `--semver` option.

### 2. Updating iOS Files

- **Info.plist**: The script updates `CFBundleShortVersionString` (which corresponds to the `MARKETING_VERSION`) and verifies the change. If the `CFBundleVersion` is set to `$(CURRENT_PROJECT_VERSION)`, it is incremented accordingly in the `project.pbxproj` file.

- **project.pbxproj**: The script also ensures that the `CURRENT_PROJECT_VERSION` is incremented.

### 3. Updating Android Files

- **build.gradle**: The script updates the `versionName` and increments the `versionCode`.

## Troubleshooting

- Ensure that the paths to `Info.plist`, `project.pbxproj`, and `build.gradle` are correctly set relative to the script.
- If you encounter issues with version increments, verify the current values in your project files to ensure they are numeric and correctly formatted.

## Conclusion

This script streamlines the versioning process in your React Native project, ensuring consistency across all platforms. By automating these updates, you can focus on developing features and fixing bugs without worrying about manual version management.

If you have any further questions or need additional assistance, feel free to reach out!

---

This `README` should provide a clear and comprehensive guide for anyone using your script, explaining its functionality and how to use it effectively.
