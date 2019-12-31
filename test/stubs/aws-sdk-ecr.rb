# rubocop:disable Naming/FileName
# rubocop:enable Naming/FileName
# frozen_string_literal: true

require 'logger'

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::INFO

# Mock for aws-sdk-ecr
class Aws
  class ECR
    # Client mock
    class Client
      def initialize(opts = {})
        raise "Fail region #{opts[:region]}" if opts[:region] != 'eu-west-1'
      end

      # rubocop:disable Naming/AccessorMethodName
      def get_authorization_token
        Aws::ECR::Token.new
      end
      # rubocop:enable Naming/AccessorMethodName

      def put_lifecycle_policy(opts = {})
        raise 'Missing repository_name' unless opts.key?(:repository_name)
        raise 'Missing lifecycle_policy_text' unless opts.key?(:lifecycle_policy_text)
      end

      def create_repository(opts = {})
        raise 'Missing repository_name' unless opts.key?(:repository_name)
      end
    end

    # Token mock
    class Token
      def authorization_data
        [Aws::ECR::Token.new]
      end

      def proxy_endpoint
        'https://111111111111.dkr.ecr.eu-west-1.amazonaws.com'
      end

      def authorization_token
        'some-aws-ecr-token'
      end
    end

    class Errors
      class RepositoryAlreadyExistsException < RuntimeError
      end
    end
  end
end

# Base64 mock
class Base64
  def self.decode64(token)
    token
  end
end
