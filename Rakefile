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
