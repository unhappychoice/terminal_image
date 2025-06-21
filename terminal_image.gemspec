# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'terminal_image/version'

Gem::Specification.new do |spec|
  spec.name                  = 'terminal_image'
  spec.version               = TerminalImage::VERSION
  spec.required_ruby_version = '>= 3.1'
  spec.authors               = ['Yuji Ueki']
  spec.email                 = ['unhappychoice@gmail.com']
  spec.summary               = 'Display images on terminal'
  spec.description           = 'Displays images on terminal'
  spec.homepage              = 'https://github.com/unhappychoice/terminal_image'
  spec.license               = 'MIT'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/unhappychoice/terminal_image'
  spec.metadata['changelog_uri']         = 'https://github.com/unhappychoice/terminal_image'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'base64', '~> 0.3'
  spec.add_dependency 'fastimage'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'codecov'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
end
