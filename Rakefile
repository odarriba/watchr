# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

RDoc::Task.new :rdoc do |rdoc|
  rdoc.main = "README.md"

  rdoc.rdoc_files.include("README.md", "app/**/*.rb", "lib/**/*.rb", "config/**/*.rb")

  rdoc.title = "Watchr"
  rdoc.options << "--all"
  rdoc.options << "--line-numbers"
  rdoc.generator = 'bootstrap'
  rdoc.rdoc_dir = "doc"
end