require 'geom3d'
require 'rubytracer'
require 'json'
require 'redis'
require 'yaml'
require_relative 'job'

class Master
  include Rubytracer
  include Geom3d

  def initialize(camera, width, height, redis)
    @camera = camera
    @width = width
    @height = height
    @redis = redis
    @outstanding = []
    @collected = []
  end

  def post_jobs
    @job_id = @redis.incr "tracer:jobs:counter"
    @height.times do |row|
      part_id = @redis.incr "tracer:jobs:#{@job_id}:counter"
      job = Job.new(@job_id, part_id, { :camera => @camera, :row => row, :width => @width })
      @redis.rpush "tracer:jobs", Marshal::dump(job)
      @outstanding << part_id
    end
  end

  def collect_jobs
    while ! @outstanding.empty?
      queue, job_serial = @redis.blpop "tracer:jobs:#{@job_id}", 0
      job = Marshal::load(job_serial)
      @collected << job
      @outstanding.delete(job.part_id)
    end
  end

  def image
    pix = @collected.sort_by! { |obj| obj.part_id }
                    .map { |obj| obj.result }
                    .flatten
                    .map { |obj| obj.to_int }
    File.open('output.json', 'w') do |file|
      file << { :height => @height, :width => @width, :id => @job_id, :data => pix }.to_json
    end

    `./convert.py`
  end
end
