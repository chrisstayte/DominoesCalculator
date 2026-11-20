# Dominoes Calculator

- Integrate app changes into `dev`. GitHub Actions runs Flutter analysis and tests for pushes to `dev` and pull requests targeting it.
- Promote reviewed app changes from `dev` to `main` when asked to prepare a release. The public repository holds the app source and its development checks.
- The private `chrisstayte/app-releases` repository handles distribution. For iOS, configure the exact public `main` commit as `validation_commit` in its `apps.json` and run `validate` there. After unsigned validation passes and the commit is approved for release, set `approved_release_commit` to the same SHA. Run `testflight` only when explicitly asked to upload.
- Store Apple credentials in the private repository's `testflight` GitHub Actions environment.
