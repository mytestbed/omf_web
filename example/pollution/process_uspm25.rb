#!/usr/bin/env ruby

require 'json'
require 'pp'
require 'csv'


data  = JSON.parse(File.read('uspm25.json'))

def calc_range(arr)

  range = {}
  sarr = arr.uniq.sort
  arr.uniq.sort.each_with_index do |l, i|
    left = 0.5 * (l - (i > 0 ? sarr[i - 1] : 999999999))
    right = 0.5 * ((sarr[i + 1] || 999999999) - l)
    left = right if left.abs > 9999
    right = left if right.abs > 9999 
    range[l] = [(l - left).round(4), l, (l + right).round(4), i]
  #  puts "#{l} --- #{left} - #{right} -- #{i} -  #{(u_lat[i + 1])}"
  end
  return range
end

latr = calc_range data['lat']
#pp latr
lonr = calc_range data['lon']

lat_e = data['lat'].map {|e| latr[e]}
lon_e = data['lon'].map {|e| lonr[e]}
ids = [lat_e, lon_e].transpose.map {|lat, lon| lat[3] * 10000 + lon[3] }


puts "Pollution range #{data['pm25'].sort[0]} - #{data['pm25'].sort[-1]}"
ls = lat_e.sort {|e| e[0]}
puts "Lat range: min: #{ls[0][0]} max: #{ls[-1][2]} cnt: #{ls.length} d: #{ls[ls.length / 2]}"
ls = lon_e.sort {|e| e[0]}
puts "Lon range: min: #{ls[0][0]} max: #{ls[-1][2]} cnt: #{ls.length} d: #{ls[ls.length / 2]}"
return

res = [ids, lat_e, lon_e].transpose.map {|r| r.flatten }
CSV.open('uspm25-map.csv', 'w') do |csv|
  csv << ["id:int",
          "south:float", "lat:float", "north:float", "lat_i:int",
          "west:float", "lon:float", "east:float", "lon_i:int"]
  res.each {|r| csv << r}
end

res = [ids, data['pm25']].transpose
CSV.open('uspm25-data.csv', 'w') do |csv|
  csv << ["id:int", "value:float"]
  res.each {|r| csv << r}
end