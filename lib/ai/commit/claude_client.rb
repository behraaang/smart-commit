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
      
      def generate_commit_message_with_feedback(diff, feedback_array)
        prompt = build_prompt_with_feedback(diff, feedback_array)
        
        response = make_request(prompt)
        extract_message(response)
      end
      
      private
      
      COMMIT_GUIDELINES = <<~GUIDELINES
        1. Use conventional commit format: type(scope): description
        2. Keep subject line under 50 characters
        3. Use imperative mood ("add" not "added")
        4. Separate subject from body with blank line
        5. Use 'feat' for new features, 'fix' for bug fixes, 'docs' for documentation, 'style' for formatting, 'refactor' for code refactoring, 'test' for tests, 'chore' for build/tooling
        6. Be clear and specific about what changed, not just "update"
        7. Explain the impact/benefit when relevant
        8. Include scope based on file structure (e.g., auth, bank, api, components)
        9. Reference any related components or services affected
        10. For breaking changes, start with 'BREAKING CHANGE:'
        11. Use bullet points in body for multiple changes
        12. Include ticket numbers in scope when available (e.g., auth(ABC-123): description)
        13. Match existing project commit style
      GUIDELINES
      
      def build_prompt(diff)
        custom_prompts = Config.custom_prompts
        custom_prompt_text = custom_prompts.empty? ? '' : "\n\nAdditional context and preferences:\n#{custom_prompts.join("\n")}"
        
        ticket_number = Git.extract_ticket_from_branch
        ticket_context = ticket_number ? "\n\nTicket number from branch: #{ticket_number} (include in scope if relevant)" : ""
        
        <<~PROMPT
          You are a helpful assistant that generates conventional commit messages.
          
          Based on the following git diff, generate a conventional commit message that:
          #{COMMIT_GUIDELINES}

          #{custom_prompt_text}#{ticket_context}
          
          Git diff:
          #{diff}
          
          Respond with the complete commit message including subject and body, preserving line breaks.
        PROMPT
      end
      
      def build_prompt_with_feedback(diff, feedback_array)
        custom_prompts = Config.custom_prompts
        custom_prompt_text = custom_prompts.empty? ? '' : "\n\nAdditional context and preferences:\n#{custom_prompts.join("\n")}"
        
        ticket_number = Git.extract_ticket_from_branch
        ticket_context = ticket_number ? "\n\nTicket number from branch: #{ticket_number} (include in scope if relevant)" : ""
        
        feedback_text = feedback_array.map.with_index { |feedback, i| "#{i + 1}. #{feedback}" }.join("\n")
        
        <<~PROMPT
          You are a helpful assistant that generates conventional commit messages.
          
          Based on the following git diff, generate a conventional commit message that:
          #{COMMIT_GUIDELINES}

          #{custom_prompt_text}#{ticket_context}
          
          IMPORTANT: The user has provided feedback on previous attempts. Please address ALL of the following feedback:
          #{feedback_text}
          
          Git diff:
          #{diff}
          
          Respond with the complete commit message including subject and body, preserving line breaks.
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