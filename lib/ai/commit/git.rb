# frozen_string_literal: true

module Ai
  module Commit
    class Git
      def self.staged_diff
        result = `git diff --cached`
        
        if $?.exitstatus != 0
          raise Error, "Failed to get git diff. Are you in a git repository?"
        end
        
        if result.empty?
          raise Error, "No staged changes found. Stage your changes with 'git add' first."
        end
        
        result
      end
      
      def self.in_git_repo?
        system('git rev-parse --git-dir', out: File::NULL, err: File::NULL)
      end
      
      def self.has_staged_changes?
        !`git diff --cached --name-only`.strip.empty?
      end
    end
  end
end