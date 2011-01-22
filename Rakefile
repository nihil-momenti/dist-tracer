require 'resque/tasks'

$: << File.join(File.dirname(__FILE__), 'lib')

task 'resque:setup' do
  require 'environment'
end

namespace :tracer do
  task :start do
    ruby './run-master.rb'
  end

  namespace :workers do
    task :setup do
      ENV['COUNT'] = `grep -c "processor" /proc/cpuinfo`.strip
      ENV['QUEUE'] = 'parts,jobs'
      #ENV['VERBOSE'] = '1'
    end

    task :start => :setup do
      puts "Spawning #{ENV['COUNT']} forks"
      Rake::Task['resque:workers'].invoke
    end
  end
end

task :default => 'tracer:start'
