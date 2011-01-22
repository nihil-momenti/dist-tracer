require 'resque/tasks'

task 'resque:setup' do
  require_relative 'job'
end

namespace :tracer do
  task :start do
    ruby './run-master.rb'
  end

  namespace :workers do
    task :setup do
      ENV['COUNT'] = `grep -c "processor" /proc/cpuinfo`.strip
      ENV['QUEUE'] = 'tracer:parts,tracer:jobs'
      #ENV['VERBOSE'] = '1'
    end

    task :start => :setup do
      puts "Spawning #{ENV['COUNT']} forks"
      Rake::Task['resque:workers'].invoke
    end
  end
end

task :default => 'tracer:start'
