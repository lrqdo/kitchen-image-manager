# frozen_string_literal: true

require 'minitest/autorun'

# Load library mocks
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/stubs"
ENV['PATH'] = "#{File.dirname(__FILE__)}/bin_mocks:#{ENV['PATH']}"
ENV['KIM_DOCKER_REGISTRY'] = '111111111111.dkr.ecr.eu-west-1.amazonaws.com'

require 'kitchen_image_manager/docker'

# Test class KimDocker
class KimDockerTest < Minitest::Test
  def test_kimdocker_utils_run_should_succeed
    assert(KimDocker::Utils.run('ps -a'))
  end

  def test_kimdocker_registry_login_should_return_instance_of_ecr
    assert_instance_of(Aws::ECR::Client, KimDocker::Registry.login)
  end

  def test_kimdocker_image_pull_should_succeed
    assert(KimDocker::Image.pull('image'))
  end

  def test_kimdocker_image_push_should_succeed
    assert(KimDocker::Image.push('repo', 'image:latest'))
  end

  def test_kimdocker_image_tag_should_succeed
    assert(KimDocker::Image.tag('repo', 'image'))
  end

  def test_kimdocker_image_commit_should_succeed
    assert(KimDocker::Image.commit('repo', 'image'))
  end
end
