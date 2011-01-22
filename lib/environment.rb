require 'redis'
require 'redis-namespace'
require 'resque'

require 'job'
require 'part'

unless $redis
  redis = Redis.new(:host => 'files3', :port => 6379)
  $redis = Redis::Namespace.new(:tracer, :redis => redis)
  Resque.redis = redis
  Resque.redis.namespace = 'resque:tracer'
end
