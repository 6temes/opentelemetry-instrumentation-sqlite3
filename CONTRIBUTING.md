# Contributing

## Releasing

Publishing the release draft is the whole release. Release Drafter keeps the draft current from the titles of PRs merged to `main`. A PR labelled `major`, `minor` or `patch` bumps that part of the version, and an unlabelled PR bumps the patch. Publishing the draft creates the `vX.Y.Z` tag. The `Release` workflow then runs CI on the tagged commit and, only if it passes, stamps the tag's version into `lib/opentelemetry/instrumentation/sqlite3/version.rb`, builds the gem and pushes it to RubyGems. There is no version-bump commit and no local step. In the repository `VERSION` stays at the placeholder `0.0.1.dev`.

Release Drafter skips prereleases: it drafts only stable releases, and it ignores published prereleases when it picks the last release to bump from.

The gem's trusted publisher on rubygems.org must name workflow `release.yml` and environment `release`.

### When a publish fails

Release tags are never moved or deleted, even when the publish for one failed. Fix the cause on `main` and release the next version from the next draft. Before publishing that draft, regenerate its notes so they also cover the changes the failed version would have shipped.
