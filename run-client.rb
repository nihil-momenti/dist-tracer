#!/usr/bin/env ruby

require 'redis'
require_relative 'client'

client = Client.new(Redis.new(:host => "linux.cosc.canterbury.ac.nz", :port => 6379))
client.process
