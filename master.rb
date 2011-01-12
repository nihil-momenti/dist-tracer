require 'geom3d'
require 'rubytracer'
require 'json'
require 'redis'
require 'yaml'

class Master
  include Rubytracer
  include Geom3d

  def initialize(camera, width, height)
    @camera = camera
    @width = width
    @height = height
    @outstanding = []
    @collected = []
  end

  def post_jobs
    @job_id = redis.incr "tracer:jobs:counter"
    @height.times do |row|
      part_id = redis.incr "tracer:jobs:#{job_id}:counter"
      job = Job.new(@job_id, part_id, { :camera => @camera, :row => row, :width => @width })
      redis.rpush "tracer:jobs", job.to_yaml
      @outstanding << job
    end
  end

  def collect_jobs
    while ! (@outstanding - @collected).empty?
      queue, job = redis.blpop "tracer:jobs:#{job_id}"
      @collected << job
    end
  end

  def image
    pix = @collected.sort_by! { |obj| obj.part_id }
                    .map { |obj| obj.result }
                    .flatten
                    .map { |obj| obj.to_int }
    File.open('output.json', 'w') do |file|
      file << { :height => @height, :width => @width, :data => pix }.to_json
    end

    `./convert.py`

    pix
  end
end
