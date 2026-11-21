# Mobile releases

The public app repository owns both development checks and beta distribution. Review the changes on dev, then promote to main. Every push to main, including a merge, automatically uploads to TestFlight and Google Play internal testing after checks and an unsigned iOS build pass. For a fresh build on either or both stores, open Actions → Mobile release → Run workflow, select main and choose testflight, play-internal or both. Both uses the same version and build number on the two stores.

## Continue the existing app listings

Before the first upload, inspect App Store Connect → Dominoes Calculator → TestFlight, including builds still processing, and Play Console → Dominoes Calculator → App bundle explorer, including testing tracks and drafts. Confirm the bundle/package ID is com.chrisstayte.dominoes. Confirm the marketing version in pubspec.yaml is appropriate for the next release.

Set the Actions repository variable MOBILE_BUILD_NUMBER_SEED to the highest integer build number or version code already used across both stores. For an unused store, count zero. For a dotted Apple build, choose a whole-number seed above its first component. Update the seed after any future manual uploads outside this workflow.

The workflow adds one to the highest of the seed, the pubspec build suffix and prior mobile-vX.Y.Z+N tags across all versions. Validation does not reserve a number. Upload runs reserve it with a tag before contacting a store. Leave reserved tags in place even after failures. Inspect store processing before retrying an ambiguous upload, then dispatch a fresh run for only the missing destination.

## Store credentials

Under Settings → Environments, restrict each environment to the selected branch main. Enter values directly in GitHub environment secrets.

- **testflight** uses ASC_API_KEY_P8 (original private key text), ASC_API_KEY_ID, ASC_API_ISSUER_ID, APPLE_DISTRIBUTION_P12_BASE64 (certificate with private key), APPLE_DISTRIBUTION_P12_PASSWORD and DOMINOES_APPSTORE_PROFILE_BASE64 (matching App Store distribution profile).
- **play-internal** uses ANDROID_KEYSTORE_BASE64 (existing registered upload keystore), ANDROID_STORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD and PLAY_SERVICE_ACCOUNT_JSON (service account authorized for internal testing on the existing Play app).

TestFlight uploads still require Apple processing. Play uploads go to internal testing. Production rollout is a separate store action.

## Promote the tested Android build

After internal testing, open Actions → Promote tested Play release to production → Run workflow. Select main and enter the internal release’s tested version code. This explicitly requests a full production rollout of that release, subject to Google review and managed publishing. It reuses the uploaded bundle and consumes no new build number. Check Publishing overview for any remaining review or publishing actions.

Configure PLAY_SERVICE_ACCOUNT_JSON in the main-only play-production environment with permission to release Domino Counter to production. Keep internal automation scoped to testing. Alternatively, select the tested release in Play Console and promote it to production there.
