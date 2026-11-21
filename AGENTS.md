# Dominoes Calculator

- Integrate changes into dev. Pushes and pull requests targeting dev run Flutter analysis and tests.
- Promote reviewed changes from dev to main when asked to prepare a release. Every push to main runs checks and an unsigned iOS build, then uploads to TestFlight and Google Play internal testing if both pass.
- Use a manual Mobile release from main for requested fresh builds on either or both stores. The workflow reserves mobile-vX.Y.Z+N on the reviewed commit before uploading. Dispatch a fresh run for a new build number after an ambiguous or partial upload.
- Configure store credentials in this repository's main-only testflight and play-internal environments. See [release setup](RELEASING.md).
