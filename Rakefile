# -*- mode: ruby; coding: utf-8 -*-

require "rake"
require "rdoc/task"
require "rake/testtask"
require "rake/clean"
require "rubygems/package_task"

require_relative "lib/open_ruby_rmk/common"

########################################
# General information
########################################

PROJECT_TITLE = "OpenRubyRMK common library"

########################################
# Gemspec
########################################

load("openrubyrmk-common.gemspec")
Gem::PackageTask.new(GEMSPEC).define

########################################
# RDoc generation
########################################

RDoc::Task.new do |rt|
  rt.rdoc_dir = "doc"
  rt.rdoc_files.include("lib/**/*.rb", "**/*.rdoc", "COPYING")
  rt.rdoc_files.exclude("server/lib/open_ruby_rmk/karfunkel/server_management/requests/*.rb")
  rt.generator = "hanna" #Ignored if not there
  rt.title = "#{PROJECT_TITLE} RDocs"
  rt.main = "README.rdoc"
end

########################################
# Tests
########################################

Rake::TestTask.new do |t|
  t.test_files = FileList["test/test_*.rb"]
end
