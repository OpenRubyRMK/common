# -*- mode: ruby; coding: utf-8 -*-

GEMSPEC = Gem::Specification.new do |spec|

  # General information
  spec.name                  = "openrubyrmk-common"
  spec.summary               = "Common library for the OpenRubyRMK's server and default client."
  spec.description           =<<DESC
This library defines all the classes that are used by both the
OpenRubyRMK's server, Karfunkel, and the default OpenRubyRMK client.
If you want to write your own OpenRubyRMK client, you can build on top
of this set of classes, it includes the basic definitions for managing
commands, requests, etc.
DESC
  spec.version               = OpenRubyRMK::Common::VERSION.gsub("-", ".")
  spec.author                = "The OpenRubyRMK Team"
  spec.email                 = "openrubyrmk@googlemail.com"
  spec.homepage              = "http://devel.pegasus-alpha.eu/projects/openrubyrmk"
  spec.platform              = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 1.9"
  
  # Dependencies
  spec.add_development_dependency("hanna-nouveau", ">= 0.2.4")

  # Gem files
  spec.files = Dir["lib/**/*.rb", "test/test_*.rb", "README.rdoc",
                   "COPYING", "VERSION"]
  
  # Options for RDoc
  spec.has_rdoc         = true
  spec.extra_rdoc_files = %w[README.rdoc COPYING]
  spec.rdoc_options     << "-t" << "#{PROJECT_TITLE} RDocs" << "-m" << "README.rdoc"
end
