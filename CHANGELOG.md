## [Unreleased]

## [0.6.0] - 2025-01-27

### Changed
- Made `aigc` the default command (no subcommand needed)
- Users can now run just `aigc` instead of `aigc commit`
- Updated all error messages to reference `aigc` instead of `smart-commit`

## [0.5.0] - 2025-01-27

### Changed
- Renamed gem from `smart-commit` to `aigc` for shorter, more convenient usage
- Updated executable name from `smart-commit` to `aigc`

## [0.4.0] - 2025-01-27

### Fixed
- Made regenerate functionality truly recursive with accumulated feedback
- Limited regenerations to maximum of 3 attempts
- Each regeneration now builds upon all previous feedback
- Improved prompt to address all accumulated feedback points

## [0.3.0] - 2025-01-27

### Added
- Regenerate functionality for commit messages with user feedback
- Users can now provide specific feedback to improve AI-generated commit messages
- Recursive regeneration - users can regenerate multiple times with different feedback
- Enhanced prompt that incorporates user feedback for better message generation

## [0.2.0] - 2025-01-27

### Added
- Edit functionality for commit messages in the `commit` command
- Users can now modify AI-generated commit messages before committing
- Support for custom editor via `$EDITOR` or `$VISUAL` environment variables
- Fallback to `nano` editor if no default editor is configured

## [0.1.0] - 2025-08-25

- Initial release
