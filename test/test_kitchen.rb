# frozen_string_literal: true

require 'minitest/autorun'

# Load library mocks
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/stubs"
ENV['PATH'] = "#{File.dirname(__FILE__)}/bin_mocks:#{ENV['PATH']}"
ENV['KIM_DOCKER_REGISTRY'] = '111111111111.dkr.ecr.eu-west-1.amazonaws.com'

require 'kitchen_image_manager/kitchen'

# Test class Kitchen
class KitchenTest < Minitest::Test
  SUITE = {
    'name' => 'default'
  }.freeze
  PLATFORM = {
    'name' => 'buster',
    'driver_config' => {
      'image' => '111111111111.dkr.ecr.eu-west-1.amazonaws.com/ci/cookbooks-lrqdo_docker-buster-default:latest'
    }
  }.freeze

  def test_kitchen_suite_should_return_name
    assert_equal('default', Kitchen::Suite.new(SUITE).name)
  end

  def test_kitchen_platform_should_return_name
    assert_equal('buster', Kitchen::Platform.new(PLATFORM).name)
  end

  def test_kitchen_platform_should_return_docker_name
    assert_equal(
      '111111111111.dkr.ecr.eu-west-1.amazonaws.com/ci/cookbooks-lrqdo_docker-buster-default:latest',
      Kitchen::Platform.new(PLATFORM).docker_image
    )
  end

  def test_kitchen_instance_should_return_name
    assert_equal(
      'default-buster',
      Kitchen::Instance.new(
        Kitchen::Platform.new(PLATFORM),
        Kitchen::Suite.new(SUITE)
      ).name
    )
  end

  def test_kitchen_instance_should_return_container_id
    assert_equal(
      '123abc',
      Kitchen::Instance.new(
        Kitchen::Platform.new(PLATFORM),
        Kitchen::Suite.new(SUITE)
      ).container_id
    )
  end

  def test_kitchen_instance_should_return_ip
    assert_equal(
      '192.168.10.0',
      Kitchen::Instance.new(
        Kitchen::Platform.new(PLATFORM),
        Kitchen::Suite.new(SUITE)
      ).ip
    )
  end

  def test_kitchen_instance_should_shutdown
    assert(
      Kitchen::Instance.new(
        Kitchen::Platform.new(PLATFORM),
        Kitchen::Suite.new(SUITE)
      ).shutdown
    )
  end

  def test_kitchen_instance_should_start
    assert(
      Kitchen::Instance.new(
        Kitchen::Platform.new(PLATFORM),
        Kitchen::Suite.new(SUITE)
      ).start
    )
  end

  def test_kitchen_run
    assert(Kitchen.run('some_command'))
  end

  def test_kitchen_create
    assert(Kitchen.create)
  end

  def test_kitchen_converge
    assert(Kitchen.converge)
  end

  def test_kitchen_destroy
    assert(Kitchen.destroy)
  end

  def test_kitchen_generate_metadata_file
    File.write(
      'metadata.template',
      <<~TPL
        version '{{VERSION}}'
      TPL
    )
    assert(Kitchen.generate_metadata_file('lrqdo_docker'))
    assert_match(/version '0\.0\.1'/, File.read('metadata.rb'))
    File.unlink('metadata.rb')
    File.unlink('metadata.template')
  end

  def test_kitchen_verify
    assert(Kitchen.verify)
  end

  def test_kitchen_exec
    assert(
      Kitchen.exec(
        'ls',
        Kitchen::Instance.new(
          Kitchen::Platform.new(PLATFORM),
          Kitchen::Suite.new(SUITE)
        )
      )
    )
  end

  def test_kitchen_platforms
    Kitchen.platforms do |platform|
      assert_instance_of(Kitchen::Platform, platform)
    end
  end

  def test_kitchen_suites
    Kitchen.suites do |suite|
      assert_instance_of(Kitchen::Suite, suite)
    end
  end

  def test_kitchen_instances
    Kitchen.instances do |instance|
      assert_instance_of(Kitchen::Instance, instance)
    end
  end
end
