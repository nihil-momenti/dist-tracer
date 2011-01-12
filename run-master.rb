#!/usr/bin/env ruby

require 'geom3d'
require 'rubytracer'
require 'redis'
require_relative 'master'

include Rubytracer
include Geom3d

WIDTH = 640
HEIGHT = 400

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

master.post_jobs
master.collect_jobs

puts master.image
