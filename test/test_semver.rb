# frozen_string_literal: true

require 'minitest/autorun'

# Load library mocks
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/stubs"
ENV['PATH'] = "#{File.dirname(__FILE__)}/bin_mocks:#{ENV['PATH']}"

require 'kitchen_image_manager/semver'

# Test class KimDocker
class SemVerTest < Minitest::Test
  def test_increment_patch
    assert_equal('1.3.5', SemVer.increment('1.3.4'))
  end

  def test_increment_minor
    assert_equal('1.3.0', SemVer.increment('1.2.5', 'minor'))
  end

  def test_increment_major
    assert_equal('1.0.0', SemVer.increment('0.3.4', 'major'))
  end
end
