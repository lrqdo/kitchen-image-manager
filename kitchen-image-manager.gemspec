Gem::Specification.new do |s|
  s.name = 'kitchen-image-manager'
  s.version = '0.1.17'
  s.summary = 'Manage Docker images for Kitchen and optimize tests.'
  s.description = 'CLI tool to manage Docker images in .kitchen.yml. Allow to prebuild Docker images for running tests faster.'
  s.authors = ['Killian KEMPS', 'Marc MILLIEN']
  s.email = 'devops@lrqdo.fr'
  s.license = 'GPL-3.0'
  s.files = [
    'lib/kitchen_image_manager.rb',
    'lib/kitchen_image_manager/docker.rb',
    'lib/kitchen_image_manager/kitchen.rb',
    'lib/kitchen_image_manager/semver.rb'
  ]
  s.executables << 'kim'
  s.homepage = 'https://laruchequiditoui.fr'
end
