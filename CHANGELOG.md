# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2019-02-07
### Added
- `fail_if_file_less_than(percentage:)` Create a danger errors if a file has a lower coverage than defined   

## [1.2.0] - 2019-01-21
### Changed
- `filename_prefix` will be checked by adding the prefix to the _git_ and the _issue_ filename [Issue](https://github.com/Kyaak/danger-cobertura/issues/6)  

## [1.1.1] - 2018-11-28
### Fixed
- Add * wildcard to have parameters in `show_coverage` due to `danger local` bug [Issue](https://github.com/danger/danger/issues/1041)

## [1.1.0] - 2018-11-28
### Added
- Option to add branch and line rate information
- Add a filename prefix

### Changed
- Exclude all files with "$" sign in name
- Support ruby 2.2 - 2.5

## [1.0.0] - 2018-11-25
### Added
- Initial release.
- Add `show_coverage` method to display a markdown table with coverage information of all modified and added files.
- Add `warn_if_file_less_than(percentage:)` method to display a warning for each file which does not achieve the minimum coverage given.
