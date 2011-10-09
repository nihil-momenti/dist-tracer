require 'resque/tasks'
require 'bundler/setup'

$: << File.join(File.dirname(__FILE__), 'lib')

require 'constructor'

task 'resque:setup' do
  require 'environment'
end

namespace :tracer do
  namespace :scene do
    rule( /^dir:(.+)$/ => [proc { |task_name| task_name.sub(%r{[/:][^/]*$}, '') } ]) do |t, args|
      dir = t.name.sub('dir:', '')
      Dir.mkdir(dir) unless Dir.exists?(dir)
    end

    task :generate do
      @view, @const_time = Constructor::generate
    end

    task :enqueue => :generate do
      @job_id, @gen_time = Constructor::enqueue @view
    end

    task :start => [:enqueue, "dir:images/#{@job_id}"] do
      p @job_id
      File.open("images/#{@job_id}/log", 'w') do |log|
        log << "Scene construction time: #{@construction_time}\n"
        log << "Job generation time: #{@generation_time}\n"
      end
    end
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
