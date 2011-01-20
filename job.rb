require 'socket'
require 'rubytracer'
require_relative 'time_block'
require_relative 'environment'

class Job
  @queue = :tracer

  attr_reader :job_id, :view

  def initialize job_id, view
    @job_id = job_id
    @view = view
  end

  def save
    $redis.set "tracer:jobs:#{@job_id}", Marshal::dump(self)
  end

  def self.get job_id
    Marshal::load $redis.get "tracer:jobs:#{job_id}"
  end

  def self.perform(job_id, row)
    colours = nil
    time = time_block do
      colours = Job.get(job_id).view.colour_of_row(row)
    end
    value = { :row => row, :colours => colours, :time => time, :hostname => Socket.gethostname }
    $redis.rpush "tracer:jobs:#{job_id}:results", Marshal::dump(value)
  end
end
