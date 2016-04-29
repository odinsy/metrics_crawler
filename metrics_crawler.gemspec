# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'metrics_crawler/version'

Gem::Specification.new do |spec|
  spec.name          = "metrics_crawler"
  spec.version       = MetricsCrawler::VERSION
  spec.authors       = ["Oleg Dianov"]
  spec.email         = ["odidoit@gmail.com"]

  spec.summary       = %q{Domain metrics crawler}
  spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "git@storage:metrics_crawler.git"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'PageRankr', '~> 4.6.0'
  spec.add_dependency 'nokogiri', '~> 1.6.6.2'
  spec.add_dependency 'parallel'
  spec.add_dependency 'ruby-progressbar'
  spec.add_dependency 'thor'

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'factory_girl'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'

end
