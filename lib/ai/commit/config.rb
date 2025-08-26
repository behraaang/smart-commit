# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module Ai
  module Commit
    class Config
      CONFIG_FILE = File.expand_path('~/.ai-commit/config.yml').freeze
      PROMPTS_FILE = '.commit-prompts'.freeze
      
      def self.api_key
        config = load_config
        config['api_key'] || ENV['ANTHROPIC_API_KEY']
      end
      
      def self.set_api_key(key)
        config = load_config
        config['api_key'] = key
        save_config(config)
      end
      
      def self.api_key_configured?
        !api_key.nil? && !api_key.empty?
      end
      
      def self.custom_prompts
        prompts_file = find_prompts_file
        return [] unless prompts_file && File.exist?(prompts_file)
        
        File.readlines(prompts_file)
            .map(&:strip)
            .reject(&:empty?)
            .reject { |line| line.start_with?('#') }
      end
      
      def self.find_prompts_file
        # Look for .commit-prompts in current directory or parent directories
        current_dir = Dir.pwd
        while current_dir != File.dirname(current_dir)
          prompts_file = File.join(current_dir, PROMPTS_FILE)
          return prompts_file if File.exist?(prompts_file)
          current_dir = File.dirname(current_dir)
        end
        nil
      end
      
      def self.has_custom_prompts?
        !custom_prompts.empty?
      end
      
      private
      
      def self.load_config
        return {} unless File.exist?(CONFIG_FILE)
        
        YAML.load_file(CONFIG_FILE) || {}
      rescue Psych::SyntaxError
        {}
      end
      
      def self.save_config(config)
        FileUtils.mkdir_p(File.dirname(CONFIG_FILE))
        File.write(CONFIG_FILE, YAML.dump(config))
        File.chmod(0o600, CONFIG_FILE) # Secure permissions
      end
    end
  end
end