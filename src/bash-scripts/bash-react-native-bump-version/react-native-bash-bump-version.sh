#!/bin/bash

# Define the paths to your project files relative to the scripts directory
PACKAGE_JSON_PATH="YOUR PACKAGE_JSON_PATH"
IOS_PROJECT_PATH="./ios/YOUR PROJECT NAME.xcodeproj/project.pbxproj"
IOS_INFO_PLIST_PATH="../ios/YOUR PROJECT NAME/Info.plist"
ANDROID_BUILD_GRADLE_PATH="../android/app/build.gradle"

# Function to display usage information
usage() {
  echo "Usage: $0 [--type major|minor|patch] [--semver version] [--skip-semver-for platform1,platform2] [--skip-code-for platform1,platform2]"
  echo "Platforms: android, ios, all"
  exit 1
}

# Initialize variables
VERSION_TYPE=""
SPECIFIC_VERSION=""
SKIP_CODE_FOR=""
SKIP_SEMVER_FOR=""

# Parse arguments
while [[ "$1" != "" ]]; do
  case $1 in
    --type)
      shift
      VERSION_TYPE=$1
      ;;
    --semver)
      shift
      SPECIFIC_VERSION=$1
      ;;
    --skip-code-for)
      shift
      SKIP_CODE_FOR=$1
      ;;
    --skip-semver-for)
      shift
      SKIP_SEMVER_FOR=$1
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Invalid option: $1"
      usage
      ;;
  esac
  shift
done

# Ensure version type or semver is provided unless skipping semver for all
if [ -z "$VERSION_TYPE" ] && [ -z "$SPECIFIC_VERSION" ] && [[ "$SKIP_SEMVER_FOR" != *"all"* ]]; then
  echo "Error: Version type or specific version must be provided unless skipping semver for all platforms."
  usage
fi

# Ensure paths are valid
if [ ! -f "$IOS_PROJECT_PATH" ]; then
  echo "Error: iOS project.pbxproj not found at $IOS_PROJECT_PATH"
  exit 1
fi

if [ ! -f "$IOS_INFO_PLIST_PATH" ]; then
  echo "Error: iOS Info.plist not found at $IOS_INFO_PLIST_PATH"
  exit 1
fi

if [ ! -f "$ANDROID_BUILD_GRADLE_PATH" ]; then
  echo "Error: Android build.gradle not found at $ANDROID_BUILD_GRADLE_PATH"
  exit 1
fi

# 1. Bump the version in package.json
if [ -z "$SPECIFIC_VERSION" ]; then
  echo "Updating version in package.json..."
  npm version $VERSION_TYPE --no-git-tag-version
  NEW_VERSION=$(node -p "require('$PACKAGE_JSON_PATH').version")
else
  echo "Setting specific version in package.json..."
  npm version --no-git-tag-version $SPECIFIC_VERSION
  NEW_VERSION=$SPECIFIC_VERSION
fi
echo "New version is $NEW_VERSION"

# 2. Update iOS version in project.pbxproj and Info.plist (if not skipped)
if [[ "$SKIP_SEMVER_FOR" != *"ios"* ]] && [[ "$SKIP_SEMVER_FOR" != *"all"* ]]; then
  echo "Updating iOS version in Info.plist..."

  # Update CFBundleShortVersionString (MARKETING_VERSION)
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$IOS_INFO_PLIST_PATH"

  # Verify that MARKETING_VERSION has been updated
  UPDATED_MARKETING_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$IOS_INFO_PLIST_PATH")
  sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $NEW_VERSION;/g" "$IOS_PROJECT_PATH"

  if [ "$UPDATED_MARKETING_VERSION" == "$NEW_VERSION" ]; then
    echo "MARKETING_VERSION successfully updated to $UPDATED_MARKETING_VERSION"
  else
    echo "Error: MARKETING_VERSION not updated correctly. Expected $NEW_VERSION, but found $UPDATED_MARKETING_VERSION"
    exit 1
  fi

  # Check if CFBundleVersion is using CURRENT_PROJECT_VERSION
  CFBundleVersion=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$IOS_INFO_PLIST_PATH")

  if [[ "$CFBundleVersion" == "\$(CURRENT_PROJECT_VERSION)" ]]; then
    # If CFBundleVersion is using $(CURRENT_PROJECT_VERSION), increment it in project.pbxproj
    echo "CFBundleVersion uses CURRENT_PROJECT_VERSION, updating in project.pbxproj..."

    # Extract the correct CURRENT_PROJECT_VERSION
    CURRENT_BUILD_NUMBER=$(grep -m 1 -Eo 'CURRENT_PROJECT_VERSION = [0-9]+' "$IOS_PROJECT_PATH" | awk '{print $3}' | tr -d ';' | tr -d '[:space:]')

    # Debugging output for tracking
    echo "Extracted Current Build Number: $CURRENT_BUILD_NUMBER"

    # Ensure we have a valid number
    if ! [[ "$CURRENT_BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
      echo "Error: CURRENT_PROJECT_VERSION is not a valid number: $CURRENT_BUILD_NUMBER"
      exit 1
    fi

    NEW_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))

    # Debugging output for tracking
    echo "New Build Number: $NEW_BUILD_NUMBER"

    # Update CURRENT_PROJECT_VERSION in project.pbxproj
    sed -i '' "s/CURRENT_PROJECT_VERSION = $CURRENT_BUILD_NUMBER;/CURRENT_PROJECT_VERSION = $NEW_BUILD_NUMBER;/g" "$IOS_PROJECT_PATH"

    echo "iOS CURRENT_PROJECT_VERSION incremented to $NEW_BUILD_NUMBER"
  else
    # If CFBundleVersion is a number, increment it directly in Info.plist
    echo "CFBundleVersion is a numeric value, updating in Info.plist..."
    NEW_BUILD_NUMBER=$((CFBundleVersion + 1))
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD_NUMBER" "$IOS_INFO_PLIST_PATH"
    echo "iOS CFBundleVersion incremented to $NEW_BUILD_NUMBER"
  fi
fi

# 3. Update Android version in build.gradle (if not skipped)
if [[ "$SKIP_SEMVER_FOR" != *"android"* ]] && [[ "$SKIP_SEMVER_FOR" != *"all"* ]]; then
  echo "Updating Android version in build.gradle..."

  # Update versionName
  sed -i '' "s/versionName \".*\"/versionName \"$NEW_VERSION\"/g" "$ANDROID_BUILD_GRADLE_PATH"

  # Increment versionCode if not skipped or if specific version is provided
  if [[ "$SKIP_CODE_FOR" != *"android"* ]] && [[ "$SKIP_CODE_FOR" != *"all"* ]]; then
    CURRENT_VERSION_CODE=$(grep -E 'versionCode [0-9]+' "$ANDROID_BUILD_GRADLE_PATH" | awk '{print $2}' | tr -d '[:space:]')

    # Ensure we have a valid number
    if ! [[ "$CURRENT_VERSION_CODE" =~ ^[0-9]+$ ]]; then
      echo "Error: versionCode is not a valid number: $CURRENT_VERSION_CODE"
      exit 1
    fi

    NEW_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))

    sed -i '' "s/versionCode $CURRENT_VERSION_CODE/versionCode $NEW_VERSION_CODE/g" "$ANDROID_BUILD_GRADLE_PATH"
    echo "Android versionCode incremented to $NEW_VERSION_CODE"
  fi
fi

echo "Versioning complete: $NEW_VERSION"
