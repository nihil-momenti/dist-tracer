require 'socket'
require 'rubytracer'

require 'job'
require 'time_block'
require 'environment'

class Part
  @queue = "parts"

  def self.perform job_id, row
    colours = nil
    time = time_block do
      colours = Job[job_id].view.colour_of_row(row)
    end
    value = { :row => row, :colours => colours, :time => time, :hostname => Socket.gethostname }
    $redis.rpush "jobs:#{job_id}:results", Marshal::dump(value)
  end
end
