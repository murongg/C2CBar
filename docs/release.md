# Release

This project uses Swift Package Manager as the source of truth and packages the executable into a macOS `.app` bundle.

## Local Package

```bash
scripts/package.sh
```

The package script creates:

- `dist/C2CBar.app`
- `dist/C2CBar-<version>-macos.dmg`

Useful environment variables:

- `VERSION=0.1.0`
- `BUNDLE_ID=com.murongg.C2CBar`
- `SIGNING_MODE=adhoc|identity|none`
- `SIGN_IDENTITY="Developer ID Application: ..."`
- `NOTARIZE=1`
- `APPLE_KEYCHAIN_PROFILE=<notarytool profile name>`

For local unsigned testing, the default `SIGNING_MODE=adhoc` is enough. For public distribution, use a Developer ID Application certificate and notarization.

## GitHub CI

`.github/workflows/ci.yml` runs on pushes to `main` and pull requests:

- `swift test`
- release build
- ad-hoc packaged app artifact upload

## GitHub Release

Create a release by pushing a tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

You can also run the `Release` workflow manually from GitHub Actions and provide a version.

The release workflow can work without Apple secrets and will upload an ad-hoc signed DMG. To produce a Developer ID signed and notarized app, configure these repository secrets:

- `DEVELOPER_ID_APPLICATION_P12`: base64 encoded `.p12` signing certificate
- `DEVELOPER_ID_APPLICATION_PASSWORD`: password for the `.p12`
- `KEYCHAIN_PASSWORD`: temporary CI keychain password
- `APPLE_ID`: Apple ID used for notarization
- `APPLE_TEAM_ID`: Apple Developer Team ID
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for notarization
