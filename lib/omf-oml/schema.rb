
require 'omf_common/lobject'
require 'omf_oml'

module OMF::OML
  
  # This class represents the schema of an OML measurement stream.
  #
  class OmlSchema < OMF::Common::LObject
    
    CLASS2TYPE = {
      TrueClass => 'boolean',
      FalseClass => 'boolean',
      String => 'string',
      Symbol => 'string',            
      Fixnum => 'decimal',
      Float => 'double',
      Time => 'dateTime'
    }
    
    # Map various type definitions (all lower case) into a single one
    ANY2TYPE = {
      'integer' => :integer,
      'int' => :integer,
      'bigint' => :integer,
      'unsigned integer' => :integer,
      'float' => :float,
      'real' => :float,
      'double' => :float,
      'text' => :string,
      'string' => :string,
      'date' => :date,
      'dateTime'.downcase => :dateTime, # should be 'datetime' but we downcase the string for comparison
      'key' => :key,      
    }

    def self.create(schema_description)
      if schema_description.kind_of? self
        return schema_description
      end
      return self.new(schema_description)
    end
    
    # Return the col name at a specific index
    #
    def name_at(index)
      @schema[index][:name]
    end
    
    # Return the col index for column named +name+
    #
    def index_for_col(name)
      name = name.to_sym
      @schema.each_with_index do |col, i|
        return i if col[:name] == name 
      end
      raise "Unknonw column '#{name}'"
    end
    
    # Return the column names as an array
    #
    def names
      @schema.collect do |col| col[:name] end
    end

    # Return the col type at a specific index
    #
    def type_at(index)
      @schema[index][:type]
    end
    
    def columns
      @schema
    end
    
    def insert_column_at(index, col)
      if col.kind_of?(Symbol) || col.kind_of?(String)
        col = [col]
      end
      if col.kind_of? Array
        # should be [name, type]
        if col.length == 1
          col = {:name => col[0].to_sym, 
                  :type => :string, 
                  :title => col[0].to_s.split('_').collect {|s| s.capitalize}.join(' ')}
        elsif col.length == 2
          col = {:name => col[0].to_sym,
                  :type => col[1].to_sym, 
                  :title => col[0].to_s.split('_').collect {|s| s.capitalize}.join(' ')}
        elsif col.length == 3
          col = {:name => col[0].to_sym, :type => col[1].to_sym, :title => col[2]}
        else
          throw "Simple column schema should consist of [name, type, title] array, but found '#{col.inspect}'"
        end
      elsif col.kind_of? Hash
        # ensure there is a :title property
        unless col[:title]
          col[:title] = col[:name].to_s.split('_').collect {|s| s.capitalize}.join(' ')
        end
      end
      
      # should normalize type
      if type = col[:type]
        unless type = ANY2TYPE[type.to_s.downcase]
          warn "Unknown type definition '#{col[:type]}', default to 'string'"
          type = :string
        end
      else
        warn "Missing type definition in '#{col[:name]}', default to 'string'"          
        type = :string
      end
      col[:type] = type
      
      col[:type_conversion] = case type
        when :string
          lambda do |r| r end
        when :key
          lambda do |r| r end
        when :integer 
          lambda do |r| r.to_i end
        when :float 
          lambda do |r| r.to_f end
        when :date 
          lambda do |r| Date.parse(r) end
        when :dateTime
          lambda do |r| Time.parse(r) end
        else raise "Unrecognized Schema type '#{type}'"
      end
                  
      @schema.insert(index, col)
    end
    
    def each_column(&block)
      @schema.each do |c| 
       block.call(c) 
      end
    end
    
    # Translate a record described in a hash of 'col_name => value'
    # to a row array
    #
    def hash_to_row(hrow, set_nil_when_missing = false)
      @schema.collect do |cdescr|
        cname = cdescr[:name]
        unless hrow.key? cname
          next nil if set_nil_when_missing
          raise "Missing record element '#{cname}' in record '#{hrow}'"
        end
        cdescr[:type_conversion].call(hrow[cname])
      end
    end
    
    # Cast each element in 'row' into its proper type according to this schema
    #
    def cast_row(raw_row)
      unless raw_row.length == @schema.length
        raise "Row needs to have same size as schema (#{raw_row.inspect})"
      end
      # This can be done more elegantly in 1.9
      row = []
      raw_row.each_with_index do |el, i|
        row << @schema[i][:type_conversion].call(el)
      end
      row
    end
    
    def describe
      @schema.map {|c| {:name => c[:name], :type => c[:type], :title => c[:title] }}
    end
    
    def to_json(*opt)
      describe.to_json(*opt)
    end
    
    protected
    
    # schema_description - Array containing [name, type*] for every column in table
    #   TODO: define format of TYPE
    #
    def initialize(schema_description)
      # check if columns are described by hashes or 2-arrays
      @schema = []
      schema_description.each_with_index do |cdesc, i|
        insert_column_at(i, cdesc)
      end
      debug "schema: '#{describe.inspect}'"
      
    end
  end # OmlSchema
  
end
