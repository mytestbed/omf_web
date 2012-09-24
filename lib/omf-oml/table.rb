
require 'monitor'

require 'omf_common/lobject'
require 'omf_oml'
require 'omf-oml/schema'
autoload :OmlIndexedTable, 'omf-oml/indexed_table'

module OMF::OML
          
  # This class represents a database like table holding a sequence of OML measurements (rows) according
  # a common schema.
  #
  class OmlTable < OMF::Common::LObject
    include MonitorMixin
    
    attr_reader :name
    attr_accessor :max_size
    attr_reader :schema
    attr_reader :offset
    
    # 
    # tname - Name of table
    # schema - OmlSchema or Array containing [name, type*] for every column in table
    #   TODO: define format of TYPE
    # opts -
    #   :max_size - keep table to that size by dropping older rows
    #   :index - only keep the latest inserted row for a unique col value - messes with row order
    #
    def initialize(tname, schema, opts = {}, &on_before_row_added)
      super tname
      
      #@endpoint = endpoint
      @name = tname
      @schema = OmlSchema.create(schema)
      @opts = opts
      if (index = opts[:index])
        @indexed_rows = {}
        @index_col = @schema.index_for_col(index)
      end
      @on_before_row_added = on_before_row_added
      @offset = 0 # number of rows skipped before the first one recorded here
      @rows = []
      @max_size = opts[:max_size]
      @on_row_added = {}
    end
    
    def rows
      @indexed_rows ? @indexed_rows.values : @rows
    end
    
    # Register +callback+ to be called to process any newly
    # offered row before it being added to internal storage.
    # The callback's argument is the new row (TODO: in what form)
    # and should return what is being added instead of the original
    # row. If the +callback+ returns nil, nothing is being added.
    #
    def on_before_row_added(&callback)
      @on_before_row_added = callback
    end
    
    # Register callback for when new rows are being added. The key
    # allows for the callback to be removed by calling this method
    # without a block. . If the 
    # optional 'offset' value is set to zero or a positive value,
    # then the currently stored values starting at this index are being 
    # immediately sent to 'proc'. 
    #
    def on_row_added(key, offset = -1, &proc)
      #debug "on_row_added: #{proc.inspect}"
      if proc
        @on_row_added[key] = proc
        if offset >= 0
          with_offset = proc.arity == 2
          rows[offset .. -1].each_with_index do |r, i|
            with_offset ? proc.call(r, offset + i) : proc.call(r)
          end
        end
      else
        @on_row_added.delete key
      end
    end
    
    # NOTE: +on_row_added+ callbacks are done within the monitor. 
    #
    def add_row(row, needs_casting = false)
      synchronize do
        _add_row(row, needs_casting)
      end
    end
    
    def indexed_by(col_name)
      OmlIndexedTable.new(col_name, self)
    end
    
    # Add an array of rows to this table
    #
    def add_rows(rows, needs_casting = false)
      synchronize do
        rows.each { |row| _add_row(row, needs_casting) }
      end
    end
    
    # Return a new table which only contains the rows of this
    # table whose value in column 'col_name' is equal to 'col_value'
    #
    def create_sliced_table(col_name, col_value, table_opts = {})
      debug "Create sliced table from '#{@name}' (rows: #{@rows.length})"
      sname = "#{@name}_slice_#{Kernel.rand}"

      st = self.class.new(name, @schema, table_opts)
      st.instance_variable_set(:@sname, sname)
      st.instance_variable_set(:@master_ds, self)      
      def st.release
        @master_ds.on_row_added(@sname) # release callback
      end

      index = @schema.index_for_col(col_name)
      on_row_added(sname, 0) do |row|
        if row[index] == col_value
          debug "Add row '#{row.inspect}'"
          st.add_row(row)
        end
      end
      st
    end
    
    def describe()
      rows
    end
    
    def data_sources
      self
    end
    
    private
    
    # NOT synchronized
    #
    def _add_row(row, needs_casting = false)
      if needs_casting
        row = @schema.cast_row(row)
      end
      #puts row.inspect
      if @on_before_row_added
        row = @on_before_row_added.call(row)
      end
      return unless row 

      if @indexed_rows
        @indexed_rows[row[@index_col]] = row
      else
        @rows << row
        if @max_size && @max_size > 0 && (s = @rows.size) > @max_size
          @rows.shift # not necessarily fool proof, but fast
          @offset = @offset + 1
        end
      end
      _notify_row_added(row)
    end
    
    def _notify_row_added(row)
      @on_row_added.each_value do |proc|
        #puts "call: #{proc.inspect}"
        if proc.arity == 1
          proc.call(row)
        else
          proc.call(row, @offset)
        end
      end
    end
    
  end # OMLTable

end
