# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module Ai
  module Commit
    class Config
      CONFIG_FILE = File.expand_path('~/.ai-commit/config.yml').freeze
      
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