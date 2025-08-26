# frozen_string_literal: true

require_relative "commit/version"
require_relative "commit/config"
require_relative "commit/cli"
require_relative "commit/claude_client"
require_relative "commit/git"

module Ai
  module Commit
    class Error < StandardError; end
  end
end
