# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Ai
  module Commit
    class ClaudeClient
      API_URL = 'https://api.anthropic.com/v1/messages'
      
      def initialize(api_key)
        @api_key = api_key
      end
      
      def generate_commit_message(diff)
        prompt = build_prompt(diff)
        
        response = make_request(prompt)
        extract_message(response)
      end
      
      def generate_commit_message_with_feedback(prev_message, diff, feedback)
        prompt = build_prompt_with_feedback(prev_message, diff, feedback)
        
        response = make_request(prompt)
        extract_message(response)
      end
      
      private
      
      def build_prompt(diff)
        custom_prompts = Config.custom_prompts
        custom_prompt_text = custom_prompts.empty? ? '' : "\n\nAdditional context and preferences:\n#{custom_prompts.join("\n")}"
        
        <<~PROMPT
          You are a helpful assistant that generates conventional commit messages.
          
          Based on the following git diff, generate a conventional commit message that:
          1. Use conventional commit format: type(scope): description
          2. Keep subject line under 50 characters
          3. Use imperative mood ("add" not "added")
          4. Separate subject from body with blank line
          5. Wrap body at 72 characters
          6. Use 'feat' for new features, 'fix' for bug fixes, 'docs' for documentation, 'style' for formatting, 'refactor' for code refactoring, 'test' for tests, 'chore' for build/tooling
          7. Be clear and specific about what changed, not just "update"
          8. Explain the impact/benefit when relevant
          9. Include scope based on file structure (e.g., auth, bank, api, components)
          10. Reference any related components or services affected
          11. For breaking changes, start with 'BREAKING CHANGE:'
          12. Use bullet points in body for multiple changes
          13. Reference ticket numbers when applicable
          14. Match existing project commit style

          #{custom_prompt_text}
          
          Git diff:
          #{diff}
          
          Respond with the complete commit message including subject and body, preserving line breaks.
        PROMPT
      end
      
      def build_prompt_with_feedback(prev_message, diff, feedback)
        custom_prompts = Config.custom_prompts
        custom_prompt_text = custom_prompts.empty? ? '' : "\n\nAdditional context and preferences:\n#{custom_prompts.join("\n")}"
        
        <<~PROMPT
          You are a helpful assistant that generates conventional commit messages.
          
          Based on the following git diff,
          1. Use conventional commit format: type(scope): description
          2. Keep subject line under 50 characters
          3. Use imperative mood ("add" not "added")
          4. Separate subject from body with blank line
          5. Wrap body at 72 characters
          6. Use 'feat' for new features, 'fix' for bug fixes, 'docs' for documentation, 'style' for formatting, 'refactor' for code refactoring, 'test' for tests, 'chore' for build/tooling
          7. Be clear and specific about what changed, not just "update"
          8. Explain the impact/benefit when relevant
          9. Include scope based on file structure (e.g., auth, bank, api, components)
          10. Reference any related components or services affected
          11. For breaking changes, start with 'BREAKING CHANGE:'
          12. Use bullet points in body for multiple changes
          13. Reference ticket numbers when applicable
          14. Match existing project commit style

          #{custom_prompt_text}
          
          You suggested a commit message of:
          #{prev_message}

          IMPORTANT: The user has provided feedback on a previous attempt. Please address their feedback:
          "#{feedback}"
          
          Git diff:
          #{diff}
          
          Change the commit message to address the feedback. and respond with the updated commit message.
        PROMPT
      end
      
      def make_request(prompt)
        uri = URI(API_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request['x-api-key'] = @api_key
        request['anthropic-version'] = '2023-06-01'
        
        request.body = {
          model: 'claude-3-haiku-20240307',
          max_tokens: 300,
          messages: [
            {
              role: 'user',
              content: prompt
            }
          ]
        }.to_json
        
        response = http.request(request)
        
        unless response.code == '200'
          raise Error, "API request failed: #{response.code} - #{response.body}"
        end
        
        JSON.parse(response.body)
      end
      
      def extract_message(response)
        content = response.dig('content', 0, 'text')
        return content.strip if content
        
        raise Error, "Unexpected response format: #{response}"
      end
    end
  end
end