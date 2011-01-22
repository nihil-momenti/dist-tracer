require 'socket'
require 'rubytracer'
require 'msgpack'

require 'time_block'
require 'environment'

class Job
  @queue = "jobs"

  attr_reader :job_id, :view

  def initialize job_id, view
    @job_id = job_id
    @view = view
  end

  def save
    $redis.set "jobs:#{@job_id}", Marshal::dump(self)
  end

  def self.[] job_id
    Marshal::load $redis.get "jobs:#{job_id}"
  end

  def self.perform job_id
    view = Job[job_id].view
    collected = []

    collection_time = time_block do
      outstanding = view.height.times.to_a
      until outstanding.empty?
        queue, result = $redis.blpop "jobs:#{job_id}:results", 0
        result = Marshal::load(result)
        collected << result
        outstanding.delete result[:row]
      end
    end
    
    generation_time = time_block do
      pix = collected.sort_by! { |result| result[:row] }
                     .map { |result| result[:colours] }
                     .flatten
                     .map { |colour| colour.to_int }
      IO.popen('./convert.py', 'w') do |w|
        w.write({ :height => view.height, :width => view.width, :id => job_id, :data => pix }.to_msgpack)
        w.close_write
      end
    end

    workers = Hash.new(0)
    collected.each do |result|
      workers[result[:hostname]] += 1
    end

    File.open(File.join('images', job_id.to_s, 'log'), 'a') do |log|
      log << "Job collection time: #{collection_time}\n"
      log << "Image composition time: #{generation_time}\n"
      log << "\n"
      log << "Total time used by clients: #{collected.map { |result| result[:time] }.inject(:+)}"
      log << "\n"
      log << "Workers used:\n"
      workers.each do |worker, count|
        log << "  #{worker} completed #{count} jobs\n"
      end
    end
  end
end
