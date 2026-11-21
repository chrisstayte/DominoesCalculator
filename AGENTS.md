# Dominoes Calculator

- Integrate changes into dev. Pushes and pull requests targeting dev run Flutter analysis and tests.
- Promote reviewed changes from dev to main when asked to prepare a release. A main push runs checks and an unsigned iOS build.
- Run Mobile release manually from main only when explicitly asked to upload to TestFlight or Google Play internal testing. The workflow reserves mobile-vX.Y.Z+N on the reviewed commit before uploading. Dispatch a fresh run for a new build number after an ambiguous or partial upload.
- Configure store credentials in this repository's main-only testflight and play-internal environments. See [release setup](RELEASING.md).
