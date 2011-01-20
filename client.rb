require 'redis'
require 'rubytracer'
require 'geom3d'
require_relative 'job'
require 'socket'
require 'pp'

class Client
  def initialize(redis)
    @redis = redis
  end

  def process
    while (job_serial = @redis.lpop 'tracer:jobs')
      start = Time.now
      job = Marshal::load(job_serial)
      
      job.result = do_stuff(job.data)
      
      end_time = Time.now
      job.time = end_time - start
      job.hostname = Socket.gethostname
      job.pid = Process.pid
      @redis.rpush "tracer:jobs:#{job.job_id}", Marshal::dump(job)
    end
  end

  def do_stuff(data)
    pp data
    row = data[:row]
    width = data[:width]
    camera = data[:camera]

    (0..width - 1).map { |col| camera.colour_of_pixel(row, col) }
  end
end
