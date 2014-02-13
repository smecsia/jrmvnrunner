require 'pathname'

require Pathname.new(File.dirname(File.expand_path(__FILE__))).join('lib/jrmvnrunner.rb')

Gem::Specification.new do |s|
  s.name = 'jrmvnrunner'
  s.version = Jrmvnrunner::VERSION
  s.date = '2013-03-02'
  s.authors = ["Ilya Sadykov"]
  s.email = 'smecsia@gmail.com'
  s.homepage = ""
  s.summary = %q{Simple lib to execute jruby task with the java classpath}
  s.description = %q{This gem allows you to specify the jar-dependencies of your project and run your tasks with the classpath}

  s.add_development_dependency 'rspec', '~> 2.10.0'
  s.add_dependency 'bundler'

  s.executables = ['jrmvnrun']
  s.default_executable = 'jrmvnrun'
  s.require_path = 'lib'
  s.files = Dir['{bin,lib,spec}/**/*','README*']
end
