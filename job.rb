class Job
  attr_reader :job_id, :part_id, :data
  attr_accessor :hostname, :pid, :result, :time

  def initialize(job_id, part_id, data)
    @job_id = job_id
    @part_id = part_id
    @data = data
  end

  def == other
    case other
    when Job
      @job_id == other.job_id && @part_id == other.part_id
    else
      super.==(other)
    end
  end
end
