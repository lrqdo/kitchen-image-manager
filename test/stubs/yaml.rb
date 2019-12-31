# frozen_string_literal: true

# Mock of YAML module
module YAML
  DEFAULT_BUSTER = { 'container_id' => '123abc' }.freeze
  KITCHEN = {
    'platforms' => [{
      'name' => 'buster',
      'driver_config' => {
        'image' => '111111111111.dkr.ecr.eu-west-1.amazonaws.com/ci/cookbooks-lrqdo_docker-buster-default:latest'
      }
    }],
    'suites' => [{
      'name' => 'default'
    }]
  }.freeze
  KITCHEN_TEMPLATE = {
    'platforms' => [{
      'name' => 'buster',
      'driver_config' => {}
    }],
    'suites' => [{
      'name' => 'default'
    }]
  }.freeze

  def self.load_file(file)
    case file
    when '.kitchen/default-buster.yml'
      DEFAULT_BUSTER.dup
    when '.kitchen.yml'
      KITCHEN.dup
    when '.kitchen.template.yml'
      KITCHEN_TEMPLATE.dup
    else
      raise "Unknown YAML fixtures for #{file}"
    end
  end

  def self.dump(data)
    raise 'YAML data should be a Hash' unless data.class == Hash
  end
end
