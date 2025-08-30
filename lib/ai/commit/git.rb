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
      
      def self.current_branch
        result = `git branch --show-current`
        result.strip if $?.exitstatus == 0
      end
      
      def self.extract_ticket_from_branch
        branch_name = current_branch
        return nil unless branch_name
        
        # Common patterns: ABC-123, PROJ-456, JIRA-789, etc.
        # Look for patterns like: feature/ABC-123, bugfix/PROJ-456, hotfix/JIRA-789
        ticket_match = branch_name.match(/(?:feature|bugfix|hotfix|fix|feat|chore|docs|style|refactor|test|perf|revert)\/([A-Z]+-\d+)/i)
        
        if ticket_match
          return ticket_match[1]
        end
        
        # Also check for ticket numbers without prefixes
        ticket_match = branch_name.match(/([A-Z]+-\d+)/)
        ticket_match ? ticket_match[1] : nil
      end
      
      def self.commit_diff(commit_hash)
        # Validate the commit hash exists
        unless system("git rev-parse --verify #{commit_hash}", out: File::NULL, err: File::NULL)
          raise Error, "Commit hash '#{commit_hash}' not found"
        end
        
        # Get the diff between HEAD and the specified commit
        result = `git diff #{commit_hash}..HEAD`
        
        if $?.exitstatus != 0
          raise Error, "Failed to get diff between #{commit_hash} and HEAD"
        end
        
        if result.empty?
          raise Error, "No differences found between #{commit_hash} and HEAD"
        end
        
        result
      end
    end
  end
end