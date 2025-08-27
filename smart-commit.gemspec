# frozen_string_literal: true

require_relative "lib/ai/commit/version"

Gem::Specification.new do |spec|
  spec.name = "smart-commit"
  spec.version = Ai::Commit::VERSION
  spec.authors = ["Behrang Mirzamani"]
  spec.email = ["behraaang@gmail.com"]

  spec.summary = "Generate intelligent conventional commit messages using Claude AI"
  spec.description = "AI-powered commit message generator that analyzes your git diff and creates meaningful, conventional commit messages using Claude AI. No more commit message writer's block!"
  spec.homepage = "https://github.com/behraaang/smart-commit"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/behraaang/smart-commit"
  spec.metadata["changelog_uri"] = "https://github.com/behraaang/smart-commit/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile Gemfile.lock]) ||
        f.end_with?('.gem')
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "net-http", "~> 0.3"
  spec.add_dependency "json", "~> 2.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
