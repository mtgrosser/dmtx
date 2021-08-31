require_relative 'lib/dmtx/version'

Gem::Specification.new do |spec|
  spec.name          = 'dmtx'
  spec.version       = Dmtx::VERSION
  spec.authors       = ['Matthias Grosser']
  spec.email         = ['mtgrosser@gmx.net']

  spec.summary       = 'Pure Ruby Datamatrix Generator'
  spec.homepage      = 'https://github.com/mtgrosser/dmtx'
  spec.required_ruby_version = '>= 2.4.0'
  spec.licenses      = ['MIT']

  spec.files = Dir['{lib}/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md', 'Rakefile']
  spec.require_paths = ['lib']
end
