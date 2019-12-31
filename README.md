# Kitchen Image Manager

Manage Docker images for Test Kitchen and optimize tests

## Description

KIM (Kitchen Image Manager) has been built as a wrapper of the `kitchen` command. It will help you to automatize some little tasks.
Do you need to run a command on all platforms of all suites in your .kitchen.yml file? `kim exec 'command'` will let you do this in one shot.

## Purpose

While using Test Kitchen to test our cookbooks in our Continuous Integration we encounter a kind of problem: our CI had to build Docker images from scratch at every push into a Github Pull Request and it could last very long.
We first conceived Kitchen Image Manager in order to build full Docker images of our cookbooks at each release in order to then pull these prebuilt images when testing our cookbooks in Github PRs.
As we could avoid rebuilding Docker images from scratch for each Pull Request we saved a lot of time!

## Basic setup

Install KIM:
```
gem build kitchen-image-manager.gemspec
gem install gem install kitchen-image-manager-0.1.17.gem
```

You can also call this script without installing it using a wrapper script like this:

``` kim
#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift 'location-to/kitchen-image-manager/lib'
ENV['KIM_DOCKER_REGISTRY'] = '111111111111.dkr.ecr.eu-west-1.amazonaws.com'
require 'kitchen_image_manager'

COMMAND = ARGV.shift
Kim::Commands.call(COMMAND, ARGV)
exit 0
```

## Usage

```
Usage: kim COMMAND

  Kitchen Image Manager (KIM) a tool to
    - facilitate our kitchen usage
    - manage pre-built docker images used in the kitchen (template based)

Commands:
  commit
    Description: Commit base containers declared in kitchen.yml to ECR
    Example: kim commit

  converge
    Description: Run kitchen converge
    Example: kim converge

  create
    Description: Run kitchen create
    Example: kim create

  destroy
    Description: Run kitchen destroy
    Example: kim destroy

  exec COMMAND
    Description: Run a command with the variables replaced on each instance in kitchen.yml
    Example: kim exec "ls /"

  generate_metadata_file patch|minor|major
    Description: Generate metadata.rb from metadata.template
    Example: kim generate_metadata_file

  login INSTANCE_NAME
    Description: Login to instance
    Example: kim login

  shutdown
    Description: Shutdown docker containers declared in .kitchen.yml
    Example: kim shutdown

  start
    Description: Start docker containers declared in .kitchen.yml
    Example: kim start

  test [--suite SUITE] [--from-scratch]
    Description: Generate kitchen.yml from template (if it exists), pull docker image, then runs kitchen test
    Example: kim test --suite COMMUNITY --from-scratch

  verify
    Description: Run kitchen verify
    Example: kim verify
```

## Docker images optimization feature

### Setup

For KIM to manipulate your prebuilt Docker images, you will need to set the address of a Docker Registry in the `KIM_DOCKER_REGISTRY` environment variable.

In order to use all the features of KIM on your cookbook, you will need to rename the `.kitchen.yml` file to `.kitchen.template.yml`.
It will allow KIM to dynamically generate the `.kitchen.yml` file with the name of the prebuilt Docker image.
For example, if you specify this in your `.kitchen.template.yml`:
```
image: 111111111111.dkr.ecr.eu-west-1.amazonaws.com/ci/debian-stretch:ca95df53fba604eeaa0a2efe09caafaa8d9155ad
```
KIM will generate this line in `.kitchen.yml` once you have built a Docker image of the cookbook
```
image: 111111111111.dkr.ecr.eu-west-1.amazonaws.com/ci/cookbooks-mygreatcookbook-stretch-default:latest
```

*Note:* The name of the prebuilt Docker image follows this pattern: `PREFIX-COOKBOOK_NAME-PLATFORM-SUITE:TAG`
- PREFIX: 'ci/cookbooks' by default which can be overriden by setting the `KIM_IMAGE_PREFIX` environment variable
- COOKBOOK_NAME: Inferred from the folder name

Also, you need to add `.kitchen.yml` to your `.gitignore` to avoid committing the dynamically generated file.

### Usage

You first need to generate the Docker image from scratch. We usually execute these commands on merge on master:
```
kim test --from-scratch
kim commit
```

You can then execute this command in PRs to run tests from the prebuilt image:
```
kim test
```

## Metadata file auto-increment feature

### Setup

To allow KIM to automatically increment the version of your cookbook when merging on branch master for example, you need to copy `metadata.rb` to `metadata.template.yml`.
Then, replace the version line like this:
```
version '1.2.3'
```

```
version '{{VERSION}}'
```

Also, you need to add `metadata.rb` to your `.gitignore` to avoid committing the dynamically generated file.

### Usage

Run the following to increase the patch version of your cookbook
```
kim generate_metadata_file patch
```

KIM knows the current version of your cookbook by requesting it to your Chef server using the `knife` tool.

## License

GNU General Public License v3

## Authors

- [Killian Kemps](https://github.com/KillianKemps)
- [Marc Millien](https://github.com/marcmillien)
