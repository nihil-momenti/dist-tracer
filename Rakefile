require 'resque/tasks'

task 'resque:setup' do
  require_relative 'job'
end

task :start do
  ruby './run-master.rb'
end

task :default => :start
