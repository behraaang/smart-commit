# frozen_string_literal: true

require 'thor'
require 'io/console'
require_relative 'config'

module Ai
  module Commit
    class CLI < Thor
      def self.exit_on_failure?
        true
      end
      desc "setup", "Configure AI Commit with your Anthropic API key"
      def setup
        puts "Welcome to AI Commit setup!"
        print "Enter your Anthropic API key: "
        api_key = STDIN.noecho(&:gets).chomp
        puts
        
        if api_key.empty?
          puts "No API key provided. Setup cancelled."
          exit 1
        end
        
        Config.set_api_key(api_key)
        puts "✓ API key saved successfully!"
        puts "You can now use 'smart-commit generate' to create commit messages."
      end
      
      desc "generate", "Generate a commit message based on staged changes"
      def generate
        unless Config.api_key_configured?
          puts "❌ No API key configured. Please run 'smart-commit setup' first."
          exit 1
        end
        
        unless Git.in_git_repo?
          puts "❌ Not in a git repository"
          exit 1
        end
        
        unless Git.has_staged_changes?
          puts "❌ No staged changes found. Stage your changes with 'git add' first."
          exit 1
        end
        
        puts "🤖 Generating commit message..."
        
        begin
          diff = Git.staged_diff
          client = ClaudeClient.new(Config.api_key)
          message = client.generate_commit_message(diff)
          
          puts "\n✨ Generated commit message:"
          puts "#{message}"
          puts "\nTo commit with this message, run:"
          puts "git commit -m \"#{message}\""
          
        rescue Error => e
          puts "❌ Error: #{e.message}"
          exit 1
        rescue => e
          puts "❌ Unexpected error: #{e.message}"
          exit 1
        end
      end
      
      desc "commit", "Generate a commit message and commit with confirmation"
      def commit
        unless Config.api_key_configured?
          puts "❌ No API key configured. Please run 'smart-commit setup' first."
          exit 1
        end
        
        unless Git.in_git_repo?
          puts "❌ Not in a git repository"
          exit 1
        end
        
        unless Git.has_staged_changes?
          puts "❌ No staged changes found. Stage your changes with 'git add' first."
          exit 1
        end
        
        puts "🤖 Generating commit message..."
        
        begin
          diff = Git.staged_diff
          client = ClaudeClient.new(Config.api_key)
          message = client.generate_commit_message(diff)
          
          puts "\n✨ Generated commit message:"
          puts "=" * 50
          puts message
          puts "=" * 50
          
          print "\nCommit with this message? (y/N/e to edit): "
          response = STDIN.gets.chomp.downcase
          
          if response == 'y' || response == 'yes'
            puts "\n🚀 Committing..."
            result = system("git", "commit", "-m", message)
            
            if result
              puts "✅ Successfully committed!"
            else
              puts "❌ Failed to commit"
              exit 1
            end
          elsif response == 'e' || response == 'edit'
            edited_message = edit_message(message)
            if edited_message && !edited_message.strip.empty?
              puts "\n🚀 Committing with edited message..."
              result = system("git", "commit", "-m", edited_message)
              
              if result
                puts "✅ Successfully committed!"
              else
                puts "❌ Failed to commit"
                exit 1
              end
            else
              puts "❌ Commit cancelled."
              exit 0
            end
          else
            puts "❌ Commit cancelled."
            exit 0
          end
          
        rescue Error => e
          puts "❌ Error: #{e.message}"
          exit 1
        rescue => e
          puts "❌ Unexpected error: #{e.message}"
          exit 1
        end
      end
      
      desc "config", "Show current configuration"
      def config
        if Config.api_key_configured?
          masked_key = Config.api_key[0..10] + "..." if Config.api_key
          puts "✓ API key configured: #{masked_key}"
        else
          puts "❌ No API key configured"
        end
        
        if Config.has_custom_prompts?
          puts "✓ Custom prompts found: #{Config.custom_prompts.length} prompt(s)"
          Config.custom_prompts.each_with_index do |prompt, i|
            puts "  #{i + 1}. #{prompt}"
          end
        else
          puts "ℹ️  No custom prompts found"
          puts "   Create a .commit-prompts file in your project root to add custom context"
        end
      end
      
      desc "init-prompts", "Create a sample .commit-prompts file"
      def init_prompts
        prompts_file = Config::PROMPTS_FILE
        
        if File.exist?(prompts_file)
          puts "❌ .commit-prompts file already exists"
          exit 1
        end
        
        sample_content = <<~PROMPTS
          # Custom commit message prompts
          # Add your project-specific context and preferences here
          # Lines starting with # are ignored
          
          # Example prompts:
          # - Always include the JIRA ticket number in the scope
          # - Use 'feat' for new features, 'fix' for bug fixes
          # - Keep descriptions under 50 characters
          # - Prefer active voice and present tense
          # - Include breaking change indicators when applicable
          
          # Your custom prompts go here:
          
        PROMPTS
        
        File.write(prompts_file, sample_content)
        puts "✅ Created #{prompts_file} with sample content"
        puts "📝 Edit the file to add your custom prompts"
      end
      
      private
      
      def edit_message(original_message)
        puts "\n📝 Opening editor to modify commit message..."
        puts "Original message will be loaded in your default editor."
        puts "Save and close the editor to commit, or close without saving to cancel."
        
        # Create a temporary file with the original message
        require 'tempfile'
        temp_file = Tempfile.new(['commit_message', '.txt'])
        temp_file.write(original_message)
        temp_file.close
        
        # Get the default editor
        editor = ENV['EDITOR'] || ENV['VISUAL'] || 'nano'
        
        # Open the file in the editor
        system("#{editor} #{temp_file.path}")
        
        # Read the edited content
        edited_content = File.read(temp_file.path)
        temp_file.unlink
        
        edited_content
      end
    end
  end
end