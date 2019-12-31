# frozen_string_literal: true

# Manage versions using semver syntax
class SemVer
  def self.increment(version, increment_type = 'patch')
    semver = version.split('.')
    case increment_type
    when 'patch'
      semver[2] = (semver[2].to_i + 1).to_s
    when 'minor'
      semver[2] = '0'
      semver[1] = (semver[1].to_i + 1).to_s
    when 'major'
      semver[2] = '0'
      semver[1] = '0'
      semver[0] = (semver[0].to_i + 1).to_s
    else
      raise "#{increment_type} is not a valid increment type please choose in #{possible_increments}"
    end

    semver.join('.')
  end
end
