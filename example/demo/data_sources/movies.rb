#
# Provides a table of information about recently released movies
#

require 'omf_oml/table'

schema = OMF::OML::OmlSchema.create [
  [:id, :int], 
  [:film, :string],
  [:studio, :string],
  [:year, :int],
  [:rt_rating, :int],
  [:aud_rating, :int],
  [:genre, :string],
  [:openingtheatres, :int],
  [:bo_average_opening, :string],
  [:d_gross, :float],
  [:f_gross, :float],
  [:ww_gross, :float],
  [:budget, :float],
  [:profit, :float],
  [:opening, :float]
]

movies = OMF::OML::OmlTable.new 'movies', schema 
#keys = schema.map { |key, type| key.to_s }

histo = {}
require 'yaml'
YAML.load_file("#{File.dirname(__FILE__)}/movies.json").each_with_index do |r, i|
  rec = Hash[r.map{ |k, v| [k.to_sym, v] }]
  rec[:id] = i
  row = schema.hash_to_row(rec, true)
  movies.add_row(row)
  
  year = histo[rec[:year]] ||= {}
  year[rec[:genre]] = (year[rec[:genre]] || 0) + 1
end

mygt = OMF::OML::OmlTable.new 'movies_year_genre', [
  [:id, :int], 
  [:year, :int],
  [:genre, :string],
  [:count, :int]
] 

i = 1
histo.each do |year, genres|
  year = year.to_i
  genres.each do |genre, count|
    #puts ">>>> #{year} - #{genre} - #{count}"
    mygt.add_row([i, year, genre, count])
    i += 1
  end
end

require 'omf_web'
OMF::Web.register_datasource movies
OMF::Web.register_datasource mygt

