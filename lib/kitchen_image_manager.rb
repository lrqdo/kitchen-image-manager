# frozen_string_literal: true

require 'yaml'
require 'logger'
require 'kitchen_image_manager/docker'
require 'kitchen_image_manager/kitchen'

# Main class
class Kim
  ECR = ENV['KIM_DOCKER_REGISTRY']
  IMAGE_PREFIX = ENV['KIM_IMAGE_PREFIX'] || 'ci/cookbooks'
  TEMPLATE = '.kitchen.template.yml'

  LOG = Logger.new(STDOUT)
  LOG.level = Logger::INFO
  LOG.formatter = proc do |_severity, _datetime, _progname, msg|
    "KIM: #{msg}\n"
  end

  # Some useful stuff
  class Utils
    # rubocop:disable Metrics/MethodLength
    def self.generate(suite = 'default', from_scratch = false)
      LOG.info("Generating kitchen.yml for suite #{suite} (from scratch: #{from_scratch})")
      conf = YAML.load_file(TEMPLATE)

      # add platform images
      conf['platforms'].each do |platform|
        platform_name = platform['name']

        default_image = platform['driver_config']['image']
        if from_scratch
          KimDocker::Image.pull(default_image) || LOG.warn("Failed to pull #{default_image}")
          next
        end

        kim_image = image(platform_name, suite)
        platform['driver_config']['image'] = kim_image
        KimDocker::Image.pull(kim_image) || KimDocker::Image.tag(default_image, kim_image)
      end

      # keep only the given suite
      suites = []
      conf['suites'].each do |suite_conf|
        if suite_conf['name'] == suite
          suites << suite_conf
          break
        end
      end
      conf['suites'] = suites

      kitchen_yml = File.open('.kitchen.yml', 'w')
      kitchen_yml.write(YAML.dump(conf))
      kitchen_yml.close

      conf
    end
    # rubocop:enable Metrics/MethodLength

    def self.cookbook
      Dir.pwd.split('/').last
    end

    def self.image(platform_name, suite)
      cookbook = Dir.pwd.match(%r{^.*/(?<cookbook>[^/]+)(/|)$})[:cookbook]
      "#{ECR}/#{IMAGE_PREFIX}-#{cookbook}-#{platform_name}-#{suite}:latest"
    end

    def self.repository(platform_name, suite)
      cookbook = Dir.pwd.match(%r{^.*/(?<cookbook>[^/]+)(/|)$})[:cookbook]
      "#{IMAGE_PREFIX}-#{cookbook}-#{platform_name}-#{suite}"
    end
  end

  # Main commands available for kim
  class Commands
    # rubocop:disable Style/ClassVars
    @@functions = {
      commit: {
        description: 'Commit base containers declared in kitchen.yml to ECR'
      },
      converge: {
        description: 'Run kitchen converge'
      },
      create: {
        description: 'Run kitchen create'
      },
      destroy: {
        description: 'Run kitchen destroy'
      },
      exec: {
        description: 'Run a command with the variables replaced on each instance in kitchen.yml',
        args_doc: 'COMMAND',
        example: '"ls /"'
      },
      generate_metadata_file: {
        description: 'Generate metadata.rb from metadata.template',
        args_doc: 'patch|minor|major'
      },
      login: {
        description: 'Login to instance',
        args_doc: 'INSTANCE_NAME'
      },
      shutdown: {
        description: 'Shutdown docker containers declared in .kitchen.yml'
      },
      start: {
        description: 'Start docker containers declared in .kitchen.yml'
      },
      test: {
        description: 'Generate kitchen.yml from template (if it exists), pull docker image, then runs kitchen test',
        args_doc: '[--suite SUITE] [--from-scratch]',
        example: '--suite COMMUNITY --from-scratch'
      },
      verify: {
        description: 'Run kitchen verify'
      }
    }
    # rubocop:enable Style/ClassVars

    # Main function
    def self.call(command, args)
      abort 'Please specify the Docker Regsitry with KIM_DOCKER_REGISTRY envvar' unless ECR
      usage if command.nil? || !@@functions.include?(command.to_sym)
      LOG.debug("Entering #{command}")
      if args.empty?
        send(command.to_sym)
      else
        send(command.to_sym, args)
      end
    end

    # How to use
    # rubocop:disable Layout/IndentHeredoc
    def self.usage
      puts <<-USAGE
Usage: #{$PROGRAM_NAME} COMMAND

  Kitchen Image Manager (KIM) a tool to
    - facilitate our kitchen usage
    - manage pre-built docker images used in the kitchen (template based)

Commands:
      USAGE
      @@functions.each do |name, info|
        args = "#{name} #{info[:args_doc]}"
        puts <<-USAGE
  #{args}
    Description: #{info[:description]}
    Example: #{$PROGRAM_NAME} #{name} #{info.key?(:example) ? info[:example] : ''}
        USAGE
        puts ''
      end
      exit 1
    end
    # rubocop:enable Layout/IndentHeredoc

    def self.commit
      Kitchen.instances do |instance|
        image = Kim::Utils.image(instance.platform.name, instance.suite.name)
        repository = Kim::Utils.repository(instance.platform.name, instance.suite.name)
        instance.shutdown \
          && KimDocker::Image.commit(instance.container_id, image) \
          && KimDocker::Image.push(repository, image) \
          && KimDocker::Image.rm(image) \
          || abort("Failed pushing #{image}")
      end
      true
    end

    def self.converge
      abort 'Converge failed' unless Kitchen.converge
      true
    end

    def self.create
      abort 'Create failed' unless Kitchen.create
      true
    end

    def self.destroy(args = [])
      instance = args[0]
      return true unless File.exist?('.kitchen.yml')
      abort 'Destroy failed' unless Kitchen.destroy(instance)
      true
    end

    def self.exec(args)
      command = args[0]
      abort 'No command given' if command.nil?
      abort '.kitchen.yml does not exist, please run test command first!' unless File.exist?('.kitchen.yml')

      exit_code = 0
      Kitchen.instances do |instance|
        exit_code += 1 unless Kitchen.exec(command, instance)
      end
      abort "Fail executing #{command}" if exit_code > 0
      true
    end

    def self.generate_metadata_file(args)
      version_change_type = args[0].nil? ? 'patch' : args[0]
      abort 'Failed generating metadata.rb' unless Kitchen.generate_metadata_file(
        Kim::Utils.cookbook,
        version_change_type
      )
    end

    def self.login(args)
      abort 'No instance given' if args[0].nil?
      Kitchen.instances do |instance|
        next unless instance.name == args[0]
        abort "Failed login to #{instance.name}" unless Kitchen.login(instance.name)
      end
    end

    def self.shutdown
      Kitchen.instances(&:shutdown)
    end

    def self.start
      Kitchen.instances(&:start)
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    def self.test(args = [])
      suite = 'default'
      from_scratch = false
      until args.empty?
        arg = args.shift
        case arg
        when '--from-scratch'
          from_scratch = true
        when '--suite'
          suite = args.shift
        else
          STDERR.puts "Argument \"#{arg}\" unknown !"
          usage
        end
      end

      # Generate .kitchen.yml from template if needed
      Kim::Utils.generate(suite, from_scratch) if File.exist?(TEMPLATE)

      # Prepare
      Kitchen.instances(&:start)
      abort 'Kitchen converge failed' unless Kitchen.create && Kitchen.converge
      Kitchen.instances do |instance|
        command = <<~SHELL
          sudo /opt/chef/embedded/bin/gem update --no-document --system 3.0.0
        SHELL
        Kitchen.exec(command, instance)
      end

      # Verify
      abort 'Kitchen test failed' unless Kitchen.verify
      true
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

    def self.verify
      abort 'Verify failed' unless Kitchen.verify
      true
    end
  end
end
