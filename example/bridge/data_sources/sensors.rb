require 'omf-oml/table'
require 'time'


require 'omf_web'


class MedianOverWindow

  def smooth(v)
    @queue << v
    l = @queue.length    
    @queue = @queue[1, @size] if l > @size
    sq = @queue.sort
    sq[l / 2]
  end

    
  def initialize(size = 100)
    @size = 100
    @queue = []
  end
end


class HoltWinter

  def smooth(v)
    if @ctxt[:prev] 
      smooth =  @alpha * v + (1 - @alpha) * @ctxt[:prev]
    else 
      # First timestep. Just use actual values
      smooth = v
    end
    @ctxt[:prev] = smooth
  end

  def smooth3(v)
    if @ctxt[:smooth] 
      # Calculate a, b, and c first, and use them to calculate the predicted (smoothed) value
      a = @ctxt[:a] = (@alpha * (@ctxt[:old] - @ctxt[:c])) + ((1 - @alpha) * (@ctxt[:a] + @ctxt[:b]))
      b = @ctxt[:b] = (@beta * (a - @ctxt[:a])) + ((1 - @beta) * @ctxt[:b])
      c = @ctxt[:c] = (@lambda * (@ctxt[:old] - a)) + ((1 - @lambda) * @ctxt[:c])
      smooth = a + b + c;
      d = @ctxt[:d] = (@lambda * (v - smooth).abs) + ((1 - @lambda) * @ctxt[:d]);
    else 
      # First timestep. Just use actual values
      smooth = v
    end
    @ctxt[:old] = v
    @ctxt[:smooth] = smooth
  end
    
  def initialize(alpha = 0.1, beta = 0.1, lambda= 0.1, delta = 2.5)
    @alpha = alpha
    @beta = beta
    @lambda = lambda
    @delta = delta
    
    @ctxt = {:old => nil, :a => 0, :b => 0, :c => 0, :d => 0}
  end
  
end

def read_sensor_data(fname, table, table2)

  start_time = nil
  sensor_names = [:left, :middle, :right]
  afn = "#{File.dirname(__FILE__)}/#{fname}"
#  puts File.open(afn, "r").read.gsub(/\r\n?/, "\n")
  smoother = 3.times.map { MedianOverWindow.new 2000 }

  rows = File.open(afn, "r").read.gsub(/\r\n?/, "\n").each_line.map do |line|
    next if line.chomp.empty? || line.start_with?('#')
    t, *s = line.chomp.split("\t")
    abs_time = Time.parse(t).to_f
    time = abs_time - (start_time ||= abs_time)
    s = s.map {|x| x.to_f }
    sensors = [s[0..2], s[3..5], s[6..8]].map do |x, y, z|
      Math.sqrt(x * x + y * y + z * z)
    end
    sm = [sensors, smoother].transpose().map do |v, sm|
      sv = sm.smooth(v)
      [v - sv, v, sv]
    end
    sm.each_with_index do |v, i|
      #puts v.inspect
      table.add_row [time, sensor_names[i], *v]
      #table2.add_row [time, sensor_names[i], *v]      
    end
    #puts sm.inspect
    table2.add_row [time, :one_two, (sm[0][0] - sm[1][0]).abs]      
    table2.add_row [time, :one_three, (sm[0][0] - sm[2][0]).abs]            
    table2.add_row [time, :two_three, (sm[1][0] - sm[2][0]).abs]            
  end
end

schema = [[:t, :float], [:sensor, :string], [:value, :float], [:raw, :float], [:smoothed, :float]]
table = OMF::OML::OmlTable.new 'raw_sensors', schema

schema2 = [[:t, :float], [:label, :string], [:delta, :float]]
table2 = OMF::OML::OmlTable.new 'diff_sensors', schema2

[
  #'test-05-23-c.txt',
  'test-05-25-bubblewrap-bangon.txt'
].each do |fname|
  read_sensor_data(fname, table, table2)
end
OMF::Web.register_datasource table
OMF::Web.register_datasource table2
