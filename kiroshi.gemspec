# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kiroshi/version'

Gem::Specification.new do |gem|
  gem.name          = 'kiroshi'
  gem.version       = Kiroshi::VERSION
  gem.authors       = ['Darthjee']
  gem.email         = ['darthjee@gmail.com']
  gem.summary       = 'Kiroshi'
  gem.description   = ''
  gem.homepage      = 'https://github.com/darthjee/kiroshi'
  gem.required_ruby_version = '>= 3.3.1'

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency 'activesupport',       '~> 7.2.x'
  gem.add_dependency 'sinclair',            '>= 3.0.0'
end
