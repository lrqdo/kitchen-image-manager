# rubocop:disable Naming/FileName
# rubocop:enable Naming/FileName
# frozen_string_literal: true

# Mock class Docker
class Docker
  class Error
    # Mock class for Error
    class NotFoundError < StandardError
      attr_reader :object

      def initialize(object)
        @object = object
      end
    end
  end

  # Mock for Container
  class Container
    FAKE_JSON = {
      'NetworkSettings' => {
        'IPAddress' => '192.168.10.0',
        'Ports' => {
          '22/tcp' => [{
            'HostPort' => '12345'
          }]
        }
      }
    }.freeze

    def self.get(container_id)
      raise 'Missing container_id' if container_id.nil?
      Docker::Container.new
    end

    def json
      FAKE_JSON.dup
    end

    def stop
      true
    end

    def start
      true
    end

    def delete(_force)
      true
    end
  end

  def self.authenticate!(opts = {})
    raise 'Missing username' unless opts.key?('username')
    raise 'Missing password' unless opts.key?('password')
    raise 'Missing email' unless opts.key?('email')
    raise 'Missing serveraddress' unless opts.key?('serveraddress')
  end
end
