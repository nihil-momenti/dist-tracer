#!/usr/bin/env ruby

require 'geom3d'
require 'rubytracer'
require 'redis'
require_relative 'master'

include Rubytracer
include Geom3d

start_time = Time.now

WIDTH = 1440
HEIGHT = 900

GOLD = Material.new(:diffuse_colour => Colour.new(0.78, 0.58, 0.09))

scene = Scene.new
scene.add_object(Sphere.new(Point.new(0,0,0.3), 0.2, GOLD))
scene.add_light(AmbientLight.new(Colour.new(0.05,0.05,0.05)))
scene.add_light(PointLight.new(Colour.new(1,1,1), Point.new(1, 0.5, 0)))

view = View.new(Point.new(0,0.5,-2),
                Point.new(0,0,0),
                Vector.new(0,1,0),
                45,
                HEIGHT,
                WIDTH,
                1)

camera = Camera.new(view, scene)

master = Master.new(camera, WIDTH, HEIGHT, Redis.new(:host => "linux.cosc.canterbury.ac.nz", :port => 6379))

construction_end_time = Time.now

master.post_jobs

job_generation_end_time = Time.now

available_hosts = `cat /netfs/share/whichprinter/csse_lab?  | sed 's/$/.cosc.canterbury.ac.nz 22/' | xargs -n2 nc -w 2 -z -v 2> /dev/null | egrep -o "cosc[0-9]+\.cosc\.canterbury\.ac\.nz"`.split << 'localhost'
available_hosts.each do |host|
  puts "Spawning clients on #{host}"
  `ssh #{host} screen -d -m "zsh -c \\"cd ~/sources/dist-tracer && ~/.rvm/bin/tracer_bundle exec ./run-client.rb\\""`
end

client_spawn_end_time = Time.now

master.collect_jobs

job_collection_end_time = Time.now

puts master.image

end_time = Time.now

puts
puts "================"
puts
puts "Total time: #{end_time - start_time}"
puts "  Scene construction time: #{construction_end_time - start_time}"
puts "  Job generation time: #{job_generation_end_time - construction_end_time}"
puts "  Client spawn time: #{client_spawn_end_time - job_generation_end_time}"
puts "  Job collection time: #{job_collection_end_time - client_spawn_end_time}"
puts "  Image composition time: #{end_time - job_collection_end_time}"
puts
puts "Total time used by clients: #{master.cpu_time}"
puts
puts "Hosts used:"
master.hosts_with_counts.each do |host, count|
  puts "  #{host} completed #{count} jobs"
end
