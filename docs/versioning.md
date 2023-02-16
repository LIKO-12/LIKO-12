
# Versioning

It's decided that there will be 3 releases channels with 2 other non-releases patterns.

## Releases Types

| Type         | Pattern                                    | Regex (in Lua format)                                  |
|--------------|--------------------------------------------|--------------------------------------------------------|
| Release      | `(major).(minor).(patch)`                  | `^(%d+)%.(%d+)%.(%d+)$`                                |
| Pre-Release  | `(major).(minor).(patch)-(pre-release id)` | `^(%d+)%.(%d+)%.(%d+)\-(.*)$`                          |
| Experimental | `experimental-YYYYMMDD-hhmm`               | `^experimental%-(%d+)%-(%d+)$` and length should be 26 |
| Development  | `(git commit id)`                          | `^%x$` and length should be `40`                       |
| Custom       | `(any)`                                    | `.*`                                                   |


### Release

> This channel is currently freezed to allow rapid development of `2.0.0`.

The full releases channel, **follows the [semver semantics](https://semver.org/)**.

It's intended for the normal classical users that don't care much about the development of the software.

They must have a stable API as the major version shouldn't be increased that easily.

### Pre-Release

> This channel is currently freezed to allow rapid development of `2.0.0`.

**Follows the [semver semantics](https://semver.org/)**.

This channels allow to provide "alpha/beta" releases for those who want to help test the release before being fully published.

It's like setting the project in wax, allows to do some final touches of breaking changes and patches without forcing a version bump.

The suggested pattern for the pre-release id is `alpha.01`, `alpha.02`, `beta.01`, ...

### Experimental

> This is the current main channel of LIKO-12 releases for now.

Provided to allow rapid development while not being constrained with backwards compatibility.

- It's expected for the release to be functional.
- It's completely expected to introduce breaking changes very often.
- `YYYMMDD` is the date and `hhmm` is the time in UTC.
### Development

Used to represent untagged releases with git info accessible (when the source-code is directly executed).

### Custom

Used to represent untagged builds with no git info accessed.

Can have a tag if `version.txt` is set, or can be tag-less if it's absent.

Such builds would be made by unofficial developers.

## Tagging a build

<!-- FIXME: This section needs to be updated as the codebase is being rewritten. -->

For releases, pre-releases and experimental builds there would be a single-line text file at `src/version.txt` containing the version tag.

## Detecting version

<!-- FIXME: This section needs to be updated as the codebase is being rewritten. -->

1. Check for the existence of `version.txt`, if so read the release tag from it.
    1. Determine the type of the release by checking the patterns in the order defined in the table above.
    2. If it doesn't match any of the patterns and turns out to be an empty file, consider it a `Custom` build with no tag.
    3. Otherwise if it had some content, then consider it a `Custom` build with that content as the tag.
2. Attempt to determine the commit id (presuming the code is run from version control).
    1. If it was read successfully, set the release type as `Development` and use the commit as the tag.
        - In the UI displaying only the first 7 hex digits is enough.
3. Consider it an untagged custom build.