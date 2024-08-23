#!/bin/bash

increment_type=""
new_version=""

# Define the paths to your project files relative to the scripts directory
PACKAGE_JSON_PATH="./YOUR PACKAGE_JSON_PATH"
IOS_PROJECT_PATH="./ios/YOUR PROJECT NAME/project.pbxproj"
IOS_INFO_PLIST_PATH="./ios/YOUR PROJECT NAME/Info.plist"
ANDROID_BUILD_GRADLE_PATH="./android/app/build.gradle"

# Function to determine the version bump type (major, minor, patch) based on commit messages
determine_version_type() {
  git fetch --tags

  local last_tag=$(git describe --tags --abbrev=0 --match "beta-*" $(git rev-list --tags --max-count=1))
  echo "Last tag: $last_tag"

  # Create the messages.txt file containing commit messages since the last tag
  if git log "$last_tag"..HEAD --no-decorate --pretty=format:"%s" > messages.txt; then
    echo "Commit messages saved to messages.txt"
  else
    echo "Failed to create messages.txt"
    exit 1
  fi

  local current_version=$(jq -r .version package.json)
  echo "Current version in package.json: $current_version"

  # Function to increment the version based on the type
  increment_version() {
    local version=$1
    local increment=$2
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    local patch=$(echo "$version" | cut -d. -f3)

    if [ "$increment" == "major" ]; then
      major=$((major + 1))
      minor=0
      patch=0
    elif [ "$increment" == "minor" ]; then
      minor=$((minor + 1))
      patch=0
    elif [ "$increment" == "patch" ]; then
      patch=$((patch + 1))
    fi

    echo "${major}.${minor}.${patch}"
  }

  # Process commit messages to determine the type of version bump needed
  while read -r message; do
    if [[ $message =~ (([a-z]+)(\(.+\))?\!:)|(BREAKING CHANGE:) ]]; then
      increment_type="major"
      break
    elif [[ $message =~ (^(feat)(\(.+\))?:) ]]; then
      if [ -z "$increment_type" ] || [ "$increment_type" == "patch" ]; then
        increment_type="minor"
      fi
    elif [[ $message =~ ^((fix|build|perf|refactor|revert|style)(\(.+\))?:) ]]; then
      if [ -z "$increment_type" ]; then
        increment_type="patch"
      fi
    fi
  done < messages.txt

  if [ -n "$increment_type" ]; then
    new_version=$(increment_version "$current_version" "$increment_type")

    echo "Determined version: $new_version"
    echo "Determined version type: $increment_type"
  else
    echo "No changes requiring a version increment."
    rm -f messages.txt
    exit 0
  fi

  # Export the increment_type so it's available globally
  increment_type="$increment_type"

  # 1. Bump the version in package.json
  echo "Updating version in package.json..."
  # Check if package.json exists
  if [ ! -f "package.json" ]; then
    echo "Error: package.json not found in the current directory."
    exit 1
  fi

  # Update the version in package.json
  jq --arg new_version "$new_version" '.version = $new_version' package.json > package.json.tmp && mv package.json.tmp package.json

  # Check if the version was updated successfully
  updated_version=$(jq -r '.version' package.json)
  if [ "$updated_version" == "$new_version" ]; then
    echo "Version successfully updated to $new_version in package.json."
  else
    echo "Error: Failed to update the version in package.json."
    exit 1
  fi
  NEW_VERSION=$(node -p "require('$PACKAGE_JSON_PATH').version")

  echo "New package.json version is $NEW_VERSION"

  # 2. Update iOS version in project.pbxproj and Info.plist (if not skipped)
    echo "Updating iOS version in Info.plist..."

    # Update CFBundleShortVersionString (MARKETING_VERSION)
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $new_version" "$IOS_INFO_PLIST_PATH"

    # Verify that MARKETING_VERSION has been updated
    UPDATED_MARKETING_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$IOS_INFO_PLIST_PATH")
    sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $new_version;/g" "$IOS_PROJECT_PATH"

    if [ "$UPDATED_MARKETING_VERSION" == "$new_version" ]; then
      echo "MARKETING_VERSION successfully updated to $UPDATED_MARKETING_VERSION"
    else
      echo "Error: MARKETING_VERSION not updated correctly. Expected $new_version, but found $UPDATED_MARKETING_VERSION"
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

  # 3. Update Android version in build.gradle (if not skipped)
  echo "Updating Android version in build.gradle..."

    # Update versionName
    sed -i '' "s/versionName \".*\"/versionName \"$NEW_VERSION\"/g" "$ANDROID_BUILD_GRADLE_PATH"

    # Increment versionCode if not skipped or if specific version is provided
    CURRENT_VERSION_CODE=$(grep -E 'versionCode [0-9]+' "$ANDROID_BUILD_GRADLE_PATH" | awk '{print $2}' | tr -d '[:space:]')

          # Ensure we have a valid number
    if ! [[ "$CURRENT_VERSION_CODE" =~ ^[0-9]+$ ]]; then
      echo "Error: versionCode is not a valid number: $CURRENT_VERSION_CODE"
      exit 1
    fi

  NEW_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))

  sed -i '' "s/versionCode $CURRENT_VERSION_CODE/versionCode $NEW_VERSION_CODE/g" "$ANDROID_BUILD_GRADLE_PATH"
  echo "Android versionCode incremented to $NEW_VERSION_CODE"

  echo "Versioning complete: $NEW_VERSION"
}

# Function to commit the version bump and create a Git tag
commit_and_tag() {
  local tag="beta-${new_version}"
  local branch_name="beta"
  local remote="YOUR REMOTE BRANCH NAME"

  echo "Committing changes..."

  git add "android/app/build.gradle" "ios/YOUR PROJECT NAME.xcodeproj/project.pbxproj" "ios/YOUR PROJECT NAME/Info.plist" "package.json"

  git commit -m "chore(release): bump build number and version to $new_version"

  git push $remote HEAD:beta -o ci.skip

  if git rev-parse "$tag" >/dev/null 2>&1; then
    echo "Tag $tag already exists. Skipping tag creation."
  else
    echo "Tagging commit with ${tag}..."
    git tag -a ${tag} -m "chore(release): create new beta version $new_version"
  fi

  echo "Pushing tags to the remote repository..."

  git push $remote --tags
}

# Main script execution
main() {
  # Determine the next version based on commit messages
  # Bump the build number and app version based on determined version type
  determine_version_type

  # Commit changes and push the tag
  commit_and_tag
}

# Execute the main function
main "$@"
