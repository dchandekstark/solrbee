
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "solrbee/version"

Gem::Specification.new do |spec|
  spec.name          = "solrbee"
  spec.version       = Solrbee::VERSION
  spec.authors       = ["David Chandek-Stark"]
  spec.email         = ["david.chandek.stark@duke.edu"]

  spec.summary       = "Solr buzz"
  spec.homepage      = "https://github.com/dchandekstark/solrbee"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rom"
  spec.add_dependency "rom-http"
  spec.add_dependency "dry-types"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-its"
end
