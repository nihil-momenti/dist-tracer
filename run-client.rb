#!/usr/bin/env ruby

require 'redis'
require_relative 'client'

cores = `grep -c "processor" /proc/cpuinfo`.to_i
cores = 1

puts "Spawning #{cores} forks"

pids = []

cores.times do
  pids << Kernel.fork do
    client = Client.new(Redis.new(:host => "linux.cosc.canterbury.ac.nz", :port => 6379))
    client.process
  end
end

pids.each do |pid|
  Process.wait(pid)
end
