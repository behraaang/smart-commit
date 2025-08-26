# AI Commit 🤖

Generate intelligent, conventional commit messages using Claude AI. No more struggling with commit message writer's block!

## Features

- ✨ **AI-Powered**: Uses Claude AI to analyze your git diff and generate meaningful commit messages
- 📝 **Conventional Commits**: Follows conventional commit format (feat, fix, docs, etc.)
- 🔒 **Secure**: API keys stored securely with proper file permissions
- 🚀 **Fast**: Quick generation with Claude 3 Haiku
- 🎯 **Smart**: Contextual analysis of your actual code changes
- 💎 **Ruby Gem**: Simple installation and usage

## Installation

Install the gem:

```bash
gem install ai-commit
```

Or add to your Gemfile:

```ruby
gem 'ai-commit'
```

## Setup

First, configure your Anthropic API key:

```bash
ai-commit setup
```

You'll be prompted to enter your API key. Get one at [Anthropic Console](https://console.anthropic.com/).

## Usage

### Basic Usage

1. Stage your changes:
   ```bash
   git add .
   ```

2. Generate a commit message:
   ```bash
   ai-commit generate
   ```

3. The tool will analyze your diff and suggest a commit message:
   ```
   ✨ Generated commit message:
   feat: add user authentication with JWT tokens
   
   To commit with this message, run:
   git commit -m "feat: add user authentication with JWT tokens"
   ```

### Commands

- `ai-commit setup` - Configure your API key
- `ai-commit generate` - Generate commit message from staged changes
- `ai-commit config` - Show current configuration
- `ai-commit help` - Show help information

## Examples

The AI generates contextual commit messages based on your actual changes:

```bash
# Adding a new feature
git add lib/user_auth.rb
ai-commit generate
# → "feat: add JWT-based user authentication system"

# Fixing a bug
git add lib/payment_processor.rb
ai-commit generate  
# → "fix: handle null payment amounts in processor"

# Documentation updates
git add README.md
ai-commit generate
# → "docs: update installation instructions"

# Refactoring code
git add lib/user_model.rb
ai-commit generate
# → "refactor: extract user validation into separate method"
```

## Configuration

### API Key Storage
- Config stored in: `~/.ai-commit/config.yml`
- File permissions: `600` (secure)
- Environment variable: `ANTHROPIC_API_KEY` (fallback)

### Customizing the Prompt
The commit message generation prompt can be customized by editing:
`lib/ai/commit/claude_client.rb` in the `build_prompt` method.

## Requirements

- Ruby 3.1.0+
- Git repository
- Anthropic API key
- Staged changes in git

## Development

After checking out the repo:

```bash
bin/setup                    # Install dependencies
rake test                   # Run tests
bin/console                 # Interactive prompt
bundle exec exe/ai-commit   # Run locally
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bmirzamani/ai-commit.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

Made with ❤️ by [Behrang Mirzamani](https://github.com/bmirzamani)