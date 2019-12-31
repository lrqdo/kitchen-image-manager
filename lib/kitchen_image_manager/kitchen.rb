# frozen_string_literal: true

require 'yaml'
require 'docker-api'
require 'logger'
require 'English'
require 'kitchen_image_manager/semver'

# Manages Kitchen
class Kitchen
  LOG = Logger.new(STDOUT)
  LOG.level = Logger::INFO
  LOG.formatter = proc do |_severity, _datetime, _progname, msg|
    "Kitchen: #{msg}\n"
  end
  def self.conf(file = '.kitchen.yml')
    YAML.load_file(file)
  end

  def self.exec(command, instance)
    run(
      "exec #{instance.name} -c '#{command}'"
      .gsub(/{container_ipaddress}/, instance.ip)
      .gsub(/{container_id}/, instance.container_id)
      .gsub(/{platform_file}/, instance.conf_file)
      .gsub(/{instance_conf_file}/, instance.conf_file)
      .gsub(/{instance}/, instance.name)
      .gsub(/{suite}/, instance.suite.name)
    )
  end

  def self.run(command, instance = nil)
    LOG.info("Running #{command}")
    if instance.nil?
      system("kitchen #{command} #{instance}")
    elsif instance.class == String
      system("kitchen #{command} #{instance}")
    else
      system("kitchen #{command} #{instance.name}")
    end
  end

  def self.create(instance = nil)
    run('create', instance)
  end

  def self.converge(instance = nil)
    run('converge', instance)
  end

  def self.destroy(instance = nil)
    run('destroy', instance)
  end

  def self.login(instance)
    run('login', instance)
  end

  def self.generate_metadata_file(cookbook, version_change_type = 'patch')
    version = SemVer.increment(
      Kitchen::Knife.cookbook_version(cookbook),
      version_change_type
    )

    File.write(
      'metadata.rb',
      File
      .read('metadata.template')
      .gsub(/{{VERSION}}/, version)
    )

    true
  end

  def self.verify(instance = nil)
    run('verify', instance)
  end

  def self.instances
    Kitchen.suites do |suite|
      Kitchen.platforms do |platform|
        yield Kitchen::Instance.new(platform, suite)
      end
    end
  end

  def self.platforms
    conf['platforms'].each do |platform|
      yield Kitchen::Platform.new(platform)
    end
  end

  def self.suites
    conf['suites'].each do |suite|
      yield Kitchen::Suite.new(suite)
    end
  end

  # Knife commands
  class Knife
    def self.run(command)
      output = `knife #{command}`
      [$CHILD_STATUS.exitstatus == 0, output]
    end

    def self.local?
      success, result = run('config get client_key')
      raise 'Failed to read your knife configuration, please check your config' unless success

      client_key = result.match(/^client_key:\s+(?<file>.*)$/)
      raise 'Failed to get "client_key" from knife configuration, please check your config' if client_key.nil?

      !File.exist?(client_key[:file])
    end

    def self.cookbook_exists?(cookbook)
      success, output = run('cookbook list')
      raise 'Failed to get cookbook list' unless success

      return false unless output =~ /^#{cookbook}\s+/

      true
    end

    def self.cookbook_version(cookbook)
      if local?
        LOG.info('It sounds like we are working in local, returning a fake version')
        return '0.0.0'
      end

      return '0.0.0' unless cookbook_exists?(cookbook)

      success, result = run("cookbook show #{cookbook}")
      raise 'Failed to get cookbook version' unless success

      result.split(/\s+/)[1]
    end
  end

  # Manages platform from kitchen.yml
  class Platform
    attr_reader :conf

    def initialize(conf)
      @conf = conf
    end

    def name
      conf['name']
    end

    # example: ecr.amazonaws.com/ci/cookbooks-lrqdo_docker-buster-community:latest
    def docker_image
      conf['driver_config']['image']
    end
  end

  # Manage suite from kitchen.yml
  class Suite
    attr_reader :conf

    def initialize(conf)
      @conf = conf
    end

    def name
      conf['name']
    end
  end

  # Manages intances from kitchen.yml
  class Instance
    attr_reader :name, :platform, :suite, :conf_file

    def initialize(platform, suite)
      @platform = platform
      @suite = suite
      @name = "#{suite.name}-#{platform.name}"
      @conf_file = ".kitchen/#{suite.name}-#{platform.name}.yml"
    end

    def conf
      Kitchen.conf(@conf_file)
    end

    def container_id
      conf['container_id']
    end

    def flush(conf)
      yml_conf = File.open(@conf_file, 'w')
      yml_conf.write(YAML.dump(conf))
      yml_conf.close

      conf
    end

    def ip
      container = Docker::Container.get(container_id)
      container.json['NetworkSettings']['IPAddress']
    rescue Errno::ENOENT => e
      LOG.debug("Shutdown: #{e.message}")
      nil
    end

    def shutdown
      container = Docker::Container.get(container_id)
      container.stop
      true
    rescue Errno::ENOENT => e
      LOG.debug("Shutdown: #{e.message}")
      true
    end

    def start
      return false if container_id.nil?
      container = Docker::Container.get(container_id)
      container.start
      new_conf = conf
      new_conf['port'] = container.json['NetworkSettings']['Ports']['22/tcp'][0]['HostPort'].to_i
      flush(new_conf)
      Kitchen.exec('sudo chmod 644 /etc/resolv.conf', self)
      true
    rescue Errno::ENOENT, Docker::Error::NotFoundError => e
      LOG.debug("Start: #{e.message}")
      Kitchen.destroy(@name) || true
    end

    def delete
      return false if container_id.nil?
      container = Docker::Container.get(container_id)
      container.delete(force: true)
    rescue Errno::ENOENT, Docker::Error::NotFoundError => e
      LOG.debug("Delete: #{e.message}")
    end
  end
end
