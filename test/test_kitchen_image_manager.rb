# frozen_string_literal: true

require 'minitest/autorun'

# Load library mocks
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/stubs"
ENV['PATH'] = "#{File.dirname(__FILE__)}/bin_mocks:#{ENV['PATH']}"
ENV['KIM_DOCKER_REGISTRY'] = '111111111111.dkr.ecr.eu-west-1.amazonaws.com'
system('touch .kitchen.yml')

require 'kitchen_image_manager'

# Test class Kim
class KimTest < Minitest::Test
  def test_kim_utils_image
    assert_equal(
      '111111111111.dkr.ecr.eu-west-1.amazonaws.com/ci/cookbooks-kitchen-image-manager-jessie-default:latest',
      Kim::Utils.image('jessie', 'default')
    )
  end

  def test_kim_utils_repository
    assert_equal(
      'ci/cookbooks-kitchen-image-manager-jessie-default',
      Kim::Utils.repository('jessie', 'default')
    )
  end

  def test_kim_utils_generate
    assert_equal(
      {
        'platforms' => [{
          'name' => 'buster',
          'driver_config' => {
            'image' =>
              '111111111111.dkr.ecr.eu-west-1.amazonaws.com/ci/cookbooks-kitchen-image-manager-buster-default:latest'
          }
        }],
        'suites' => [{
          'name' => 'default'
        }]
      },
      Kim::Utils.generate
    )
  end

  def test_kim_commands_commit
    assert(Kim::Commands.commit)
  end

  def test_kim_commands_converge
    assert(Kim::Commands.converge)
  end

  def test_kim_commands_create
    assert(Kim::Commands.create)
  end

  def test_kim_commands_shutdown
    assert(Kim::Commands.shutdown)
  end

  def test_kim_commands_start
    assert(Kim::Commands.start)
  end

  def test_kim_commands_destroy
    assert(Kim::Commands.destroy)
  end

  def test_kim_commands_verify
    assert(Kim::Commands.verify)
  end

  def test_kim_commands_test
    assert(Kim::Commands.test)
  end

  def test_kim_commands_exec
    assert(Kim::Commands.exec(['ls /']))
  end

  def test_kim_commands_exec_on_all_instances
    assert(Kim::Commands.exec(['ls /']))
  end
end
