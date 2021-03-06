# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'becloud/version'

Gem::Specification.new do |spec|
  spec.name          = 'becloud'
  spec.version       = Becloud::VERSION
  spec.authors       = ['Dmitry Gubitskiy']
  spec.email         = ['d.gubitskiy@gmail.com']

  spec.summary       = 'Data obfuscation for Postgres'
  spec.homepage      = 'http://example.com'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.49.0'
  spec.add_development_dependency 'pry', '~> 0.10'

  spec.add_runtime_dependency 'sequel', '~> 4.47'
  spec.add_runtime_dependency 'pg', '~> 0.20.0'
  spec.add_runtime_dependency 'faker', '~> 1.7'
end
