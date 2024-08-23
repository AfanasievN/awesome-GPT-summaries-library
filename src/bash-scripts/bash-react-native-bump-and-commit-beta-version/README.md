Here's a detailed `README.md` documentation for your shell script:

---

# Bump Beta Version Script

This script automates the process of bumping the version and build number for a React Native project's beta release. It updates the version in the `package.json`, iOS `Info.plist`, and Android `build.gradle` files based on commit messages, and then commits and tags the new beta version in the GitLab repository.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Features](#features)
- [Usage](#usage)
- [Script Details](#script-details)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Prerequisites

Before using this script, ensure that you have the following installed and configured:

- **Git**: For managing the repository and creating tags.
- **Node.js**: To run JavaScript commands and tools.
- **jq**: A command-line JSON processor for updating `package.json`.
- **PlistBuddy** (macOS only): For updating the iOS `Info.plist` file.
- **NPM_TOKEN**: A GitLab authentication token for pushing changes to the repository.

## Features

- **Automated Version Bumping**: Automatically increments the version number based on commit messages.
- **Cross-Platform Support**: Updates the version in `package.json`, iOS `Info.plist`, and Android `build.gradle`.
- **Git Integration**: Commits the changes and tags the new version in the GitLab repository.

## Usage

### Running the Script

To run the script, navigate to the directory where the script is located and execute:

```bash
./bump-beta-version.sh
```

### What the Script Does

1. **Fetches the Latest Beta Tag**: Identifies the last beta tag in the GitLab repository.
2. **Determines the Version Increment**: Analyzes commit messages to determine whether to increment the major, minor, or patch version.
3. **Updates Project Files**:
    - Updates the version in `package.json`.
    - Updates the `CFBundleShortVersionString` and `CFBundleVersion` in iOS `Info.plist`.
    - Updates the `versionName` and `versionCode` in Android `build.gradle`.
4. **Commits and Tags**:
    - Commits the updated files.
    - Creates a new beta tag and pushes it to the GitLab repository.

## Script Details

### Functions

- **determine_version_type()**:
    - Fetches commit messages since the last beta tag.
    - Determines whether the changes warrant a major, minor, or patch version bump.
    - Updates the version in `package.json`, iOS `Info.plist`, and Android `build.gradle`.

- **commit_and_tag()**:
    - Commits the version changes to the repository.
    - Creates and pushes a new beta tag to the GitLab repository.

### Files Updated

- **`package.json`**: The version field is updated.
- **iOS `Info.plist`**:
    - `CFBundleShortVersionString` is updated to the new version.
    - `CFBundleVersion` is incremented.
- **Android `build.gradle`**:
    - `versionName` is updated to the new version.
    - `versionCode` is incremented.

## Environment Variables

- **`NPM_TOKEN`**: Required for authenticating with the GitLab repository to push changes and tags.

## Troubleshooting

- **Issue**: The script fails to find `package.json`.
    - **Solution**: Ensure you are in the correct directory where `package.json` is located or adjust the `PACKAGE_JSON_PATH` variable in the script.

- **Issue**: `PlistBuddy` errors on macOS.
    - **Solution**: Ensure that `PlistBuddy` is installed and the `IOS_INFO_PLIST_PATH` is correctly set.

- **Issue**: Git fails to push the commit or tag.
    - **Solution**: Ensure that `NPM_TOKEN` is correctly set and that you have the necessary permissions to push to the repository.

## License

This script is provided under the MIT License. Feel free to modify and use it as needed.

---

This `README.md` should give users a clear understanding of the purpose, usage, and functionality of your shell script.
