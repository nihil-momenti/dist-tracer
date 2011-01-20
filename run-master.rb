#!/usr/bin/env ruby

require 'geom3d'
require 'rubytracer'
require 'redis'
require 'resque'

require_relative 'job'
require_relative 'time_block'
require_relative 'environment'

include Rubytracer
include Geom3d

collected = []
times = []
total_time = time_block do
  width = height = view = nil
  times << time_block do
    width = 1440
    height = 900
    GOLD = Material.new(:diffuse_colour => Colour.new(0.78, 0.58, 0.09), :specular_colour => Colour.new(0.1, 0.1, 0.1), :shininess => 10)
    
    scene = Scene.new
    scene.add_object(Shapes::Sphere.new(Point.new(0,0,0.3), 0.2, GOLD))
    scene.add_light(Lights::Ambient.new(Colour.new(0.05,0.05,0.05)))
    scene.add_light(Lights::Point.new(Colour.new(1,1,1), Point.new(1, 0.5, 0)))
    
    view = View.create(Point.new(0,0.5,-2),
                       Point.new(0,0,0),
                       Vector.new(0,1,0),
                       45,
                       height,
                       width,
                       1,
                       scene)
    
  end
  
  job_id = nil
  times << time_block do
    job_id = $redis.incr "tracer:jobs:counter"
    Job.new(job_id, view).save
    height.times do |row|
      Resque.enqueue Job, job_id, row
    end
  end
  
#  client_spawn_time = time_block do
#    available_hosts = `cat /netfs/share/whichprinter/csse_lab?  | sed 's/$/.cosc.canterbury.ac.nz 22/' | xargs -n2 nc -w 2 -z -v 2> /dev/null | egrep -o "cosc[0-9]+\.cosc\.canterbury\.ac\.nz"`.split << 'localhost'
#    available_hosts.each do |host|
#      puts "Spawning clients on #{host}"
#      `ssh #{host} screen -d -m "zsh -c \\"cd ~/sources/dist-tracer && QUEUE='*' rake resque:work \\""`
#    end
#  end
  
  times << time_block do
    outstanding = view.height.times.to_a
    until outstanding.empty?
      queue, result = $redis.blpop "tracer:jobs:#{job_id}:results", 0
      result = Marshal::load(result)
      collected << result
      outstanding.delete result[:row]
    end
  end
  
  times << time_block do
    pix = collected.sort_by! { |result| result[:row] }
                   .map { |result| result[:colours] }
                   .flatten
                   .map { |colour| colour.to_int }
    File.open('output.json', 'w') do |file|
      file << { :height => height, :width => width, :id => job_id, :data => pix }.to_json
    end
    `./convert.py`
  end
end

puts
puts "================"
puts
puts "Total time: #{total_time}"
puts "  Scene construction time: #{times.pop}"
puts "  Job generation time: #{times.pop}"
#puts "  Client spawn time: #{client_spawn_time}"
puts "  Job collection time: #{times.pop}"
puts "  Image composition time: #{times.pop}"
puts
puts "Total time used by clients: #{collected.map { |result| result[:time].inject(:+) }}"
puts
puts "Hosts used:"

hash = Hash.new(0)
collected.each do |result|
  hash[result[:hostname]] += 1
end

hash.each do |host, count|
  puts "  #{host} completed #{count} jobs"
end
