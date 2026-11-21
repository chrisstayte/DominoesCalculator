# Dominoes Calculator

- Integrate changes into dev. Pushes and pull requests targeting dev run Flutter analysis and tests.
- Promote reviewed changes from dev to main when asked to prepare a release. Every push to main uploads to TestFlight and Google Play internal testing only after checks pass and both signed builds pass validation.
- Use a manual Mobile release from main for requested fresh builds on either or both stores. The workflow reserves mobile-vX.Y.Z+N on the reviewed commit before uploading. Dispatch a fresh run for a new build number after an ambiguous or partial upload.
- Configure store credentials in this repository's main-only testflight and play-internal environments. See [release setup](RELEASING.md).
- For Apple signing, check iCloud Drive → Development → Apple Signing and its recovery notes before creating another certificate. The distribution identity can serve multiple apps on the same Apple team. Use a provisioning profile for each app’s bundle ID.
- Google Play publishing key backups for Domino Counter are in iCloud Drive → Development → FlutterGoogleUpload → Service Accounts → Domino Counter.
