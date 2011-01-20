require 'redis'
require 'resque'

$reids or Resque.redis = $redis = Redis.new(:host => 'linux.cosc.canterbury.ac.nz', :port => 6379)
