require 'rake'
require 'spec'
require 'spec/rake/spectask'

desc 'Default: run unit tests.'
task :default => :spec
 
desc 'Test the refraction plugin.'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << 'lib'
  t.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "refraction"
    gem.summary = %Q{Rack middleware replacement for mod_rewrite}
    gem.description = %Q{Reflection is a Rails plugin and standalone Rack middleware library. Give up quirky config syntax and use plain old Ruby for your rewrite and redirection rules.}
    gem.email = "gems@pivotallabs.com"
    gem.homepage = "http://github.com/pivotal/refraction"
    gem.authors = ["Pivotal Labs", "Josh Susser", "Sam Pierson", "Wai Lun Mang"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end
