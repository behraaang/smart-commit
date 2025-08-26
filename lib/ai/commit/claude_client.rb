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
      
      private
      
      def build_prompt(diff)
        <<~PROMPT
          You are a helpful assistant that generates conventional commit messages.
          
          Based on the following git diff, generate a single line commit message that:
          1. Follows conventional commit format (type(scope): description)
          2. Uses present tense ("add" not "added")
          3. Is concise but descriptive
          4. Common types: feat, fix, docs, style, refactor, test, chore
          5. Short, confident, direct
          6. Reads like prose, not ticket numbers
          7. Often imperative, sometimes witty
          8. Emphasizes clarity over ceremony
          
          Git diff:
          #{diff}
          
          Respond with only the commit message, nothing else.
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
          max_tokens: 100,
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