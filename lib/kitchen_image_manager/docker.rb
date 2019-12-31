# frozen_string_literal: true

require 'aws-sdk-ecr'

# Manages docker
class KimDocker
  LOG = Logger.new(STDOUT)
  LOG.level = Logger::INFO
  LOG.formatter = proc do |_severity, _datetime, _progname, msg|
    "Docker: #{msg}\n"
  end

  LIFECYCLE_POLICIES = <<-POLICY
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep only one untagged image, expire all others",
        "selection": {
          "tagStatus": "untagged",
          "countType": "imageCountMoreThan",
          "countNumber": 1
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  POLICY

  # Some useful functions
  class Utils
    def self.run(command)
      LOG.info(command)
      system("docker #{command}")
    end
  end

  # Manager docker registry
  class Registry
    def self.login
      ecr_client = Aws::ECR::Client.new(region: 'eu-west-1')
      token = ecr_client.get_authorization_token.authorization_data.first
      # Remove the https:// to authenticate
      ecr_repo_url = token.proxy_endpoint.gsub('https://', '')
      # Authorization token is given as username:password, split it out
      user_pass_token = Base64.decode64(token.authorization_token).split(':')
      # Call the authenticate method with the options
      Docker.authenticate!(
        'username' => user_pass_token.first,
        'password' => user_pass_token.last,
        'email' => 'none',
        'serveraddress' => ecr_repo_url
      )
      ecr_client
    end
  end

  # Manages classic images
  class Image
    def self.commit(id, destination)
      KimDocker::Utils.run("commit #{id} #{destination}")
    end

    # args examples:
    # - image: ecr.amazonaws.com/ci/cookbooks-lrqdo_docker-buster-community:latest
    # return:
    # - true / false : success / failure
    def self.pull(image)
      LOG.debug("Pulling #{image}")
      KimDocker::Registry.login
      KimDocker::Utils.run("pull #{image}")
    end

    # args examples:
    # - repository: ci/cookbooks-lrqdo_docker-buster-community
    # - image: ecr.amazonaws.com/ci/cookbooks-lrqdo_docker-buster-community:latest
    # return:
    # - true / false : success / failure
    def self.push(repository, image)
      ecr = KimDocker::Registry.login
      begin
        ecr.create_repository(repository_name: repository)
      rescue Aws::ECR::Errors::RepositoryAlreadyExistsException => e
        LOG.info(e.message)
      end
      begin
        ecr.put_lifecycle_policy(repository_name: repository, lifecycle_policy_text: LIFECYCLE_POLICIES)
      rescue NoMethodError => e
        LOG.warn("You should upgrade aws-sdk-ecr #{e.message}")
      end

      KimDocker::Utils.run("push #{image}")
    end

    def self.tag(source, destination)
      KimDocker::Image.pull(source)
      KimDocker::Utils.run("tag #{source} #{destination}") \
        || KimDocker::Utils.run("tag -f #{source} #{destination}")
    end

    # args examples:
    # - image: ecr.amazonaws.com/ci/cookbooks-lrqdo_docker-buster-community:latest
    # return:
    # - true / false : success / failure
    def self.rm(image)
      LOG.debug("Deleting #{image}")
      KimDocker::Utils.run("rmi #{image}")
    end
  end
end
