# Repository Guidelines

## Project Structure & Module Organization
This repository is a small SwiftUI app with a single target named “Rename Files to UUID.” Source files live in `Rename Files to UUID/`, including `Rename_Files_to_UUIDApp.swift` (app entry point), `ContentView.swift` (main UI), and `Assets.xcassets` (images and app assets). Project configuration lives in `Rename Files to UUID.xcodeproj/` with `project.pbxproj`, `project.xcworkspace`, and user-specific `xcuserdata` (keep `xcuserdata` local).

## Build, Test, and Development Commands
Run these from the parent directory of the `.xcodeproj`:
- `xcodebuild -project "Rename Files to UUID.xcodeproj" -scheme "Rename Files to UUID" -configuration Debug build` — builds the app.
- `xcodebuild -project "Rename Files to UUID.xcodeproj" -scheme "Rename Files to UUID" -configuration Debug test` — runs tests (once a test target exists).
- `open "Rename Files to UUID.xcodeproj"` — open the project in Xcode.

## Coding Style & Naming Conventions
Use standard Swift/Xcode formatting: 4-space indentation, braces on the same line, and trailing commas where Xcode inserts them. Name files to match the primary type (e.g., `ContentView.swift` for `ContentView`). Use `UpperCamelCase` for types and `lowerCamelCase` for properties/functions. No SwiftLint/SwiftFormat config is present, so prefer Xcode’s built-in formatting tools.

## Testing Guidelines
No XCTest targets were found in this project. If you add tests, create a `Rename Files to UUIDTests` target and use XCTest. Name tests `test<Behavior>` (for example, `testRenamesFilesWithUUIDs`). Run tests with the `xcodebuild ... test` command above or via Xcode’s Test navigator.

## Commit & Pull Request Guidelines
No Git history is available in this directory. Use short, imperative commit messages like “Add UUID renaming validation.” For PRs, include a brief summary, steps to verify, and screenshots for any UI changes. Link related issues when applicable.

## Configuration & Signing Tips
Keep personal signing settings out of shared files when possible. If signing or build settings need to be shared, prefer `.xcconfig` files and document them here.
