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
      
      default_command :commit
      
      desc "commit", "Generate a commit message and commit with confirmation (default command)"
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
        puts "You can now use 'aigc' to create commit messages."
      end
      
      desc "generate", "Generate a commit message based on staged changes"
      def generate
        unless Config.api_key_configured?
          puts "❌ No API key configured. Please run 'aigc setup' first."
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
          puts "❌ No API key configured. Please run 'aigc setup' first."
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
          
          print "\nCommit with this message? (y/N/e to edit/r to regenerate): "
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
          elsif response == 'r' || response == 'regenerate'
            regenerate_with_feedback(diff, client, 1, [])
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
      
      def regenerate_with_feedback(diff, client, attempt = 1, accumulated_feedback = [])
        if attempt > 3
          puts "\n⚠️  Maximum regenerations (3) reached. Please commit with the current message or edit it manually."
          return
        end
        
        puts "\n💬 What would you like to change about the commit message? (Attempt #{attempt}/3)"
        puts "Examples: 'make it more concise', 'add more detail about the bug fix', 'change the type to feat'"
        if !accumulated_feedback.empty?
          puts "Previous feedback: #{accumulated_feedback.join(', ')}"
        end
        print "Feedback: "
        feedback = STDIN.gets.chomp.strip
        
        if feedback.empty?
          puts "❌ No feedback provided. Cancelling regeneration."
          return
        end
        
        # Add current feedback to accumulated list
        all_feedback = accumulated_feedback + [feedback]
        
        puts "\n🤖 Regenerating commit message with your feedback..."
        
        begin
          new_message = client.generate_commit_message_with_feedback(diff, all_feedback)
          
          puts "\n✨ New commit message:"
          puts "=" * 50
          puts new_message
          puts "=" * 50
          
          print "\nCommit with this message? (y/N/e to edit/r to regenerate again): "
          response = STDIN.gets.chomp.downcase
          
          if response == 'y' || response == 'yes'
            puts "\n🚀 Committing..."
            result = system("git", "commit", "-m", new_message)
            
            if result
              puts "✅ Successfully committed!"
            else
              puts "❌ Failed to commit"
              exit 1
            end
          elsif response == 'e' || response == 'edit'
            edited_message = edit_message(new_message)
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
          elsif response == 'r' || response == 'regenerate'
            regenerate_with_feedback(diff, client, attempt + 1, all_feedback)
          else
            puts "❌ Commit cancelled."
            exit 0
          end
          
        rescue Error => e
          puts "❌ Error regenerating message: #{e.message}"
          exit 1
        rescue => e
          puts "❌ Unexpected error: #{e.message}"
          exit 1
        end
      end
    end
  end
end