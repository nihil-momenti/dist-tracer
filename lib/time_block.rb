def time_block &blk
  start_time = Time.now
  blk.call
  return Time.now - start_time
end
