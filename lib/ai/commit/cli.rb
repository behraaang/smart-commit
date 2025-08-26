# frozen_string_literal: true

require 'thor'
require 'io/console'
require_relative 'config'

module Ai
  module Commit
    class CLI < Thor
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
        puts "You can now use 'ai-commit generate' to create commit messages."
      end
      
      desc "generate", "Generate a commit message based on staged changes"
      def generate
        unless Config.api_key_configured?
          puts "❌ No API key configured. Please run 'ai-commit setup' first."
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
      
      desc "config", "Show current configuration"
      def config
        if Config.api_key_configured?
          masked_key = Config.api_key[0..10] + "..." if Config.api_key
          puts "✓ API key configured: #{masked_key}"
        else
          puts "❌ No API key configured"
        end
      end
    end
  end
end