require 'geom3d'
require 'rubytracer'

require 'job'
require 'part'
require 'time_block'
require 'environment'

include Rubytracer
include Geom3d

module Constructor
  def self.generate
    width = 1440
    height = 900
    view = nil
    
    construction_time = time_block do
      gold = Material.new(:diffuse_colour => Colour.new(0.78, 0.58, 0.09), :specular_colour => Colour.new(0.1, 0.1, 0.1), :shininess => 10)
      
      scene = Scene.new
      scene.add_object(Shapes::Sphere.new(Point.new(0,0,0.3), 0.2, gold))
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

    return view, construction_time
  end

  def self.enqueue view
    job_id = $redis.incr "jobs:counter"
    generation_time = time_block do
      Job.new(job_id, view).save
      view.height.times do |row|
        Resque.enqueue Part, job_id, row
      end
      Resque.enqueue Job, job_id
    end

    return job_id, generation_time
  end
end
