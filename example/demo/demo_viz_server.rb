#ENV['BUNDLE_GEMFILE'] = "#{File.dirname(__FILE__)}/../../Gemfile"
#require 'bundler/setup'
require 'omf_base/lobject'
OMF::Base::Loggable.init_log 'demo', :searchPath => File.dirname(__FILE__)


require 'omf_oml/table'
require 'omf_web'

class OmfWebDemo

  # Configure the web server
  #
  OPTS = {
    :app_name => 'demo',
    :page_title => 'Vizualisation Demo',
    :static_dirs_pre => ["#{File.dirname(__FILE__)}/htdocs"],
    :handlers => {
      # delay connecting to databases to AFTER we may run as daemon
      :pre_rackup => lambda { OmfWebDemo.load_environment },
    }
  }

  def self.start(opts = OPTS)
    #self.load_environemnt()
    OMF::Web.start(opts)
  end

  def self.load_environment
    #require 'omf-web/content/file_repository'
    #OMF::Web::FileContentRepository.register_file_repo(:demo, File.join(File.dirname(__FILE__), 'repository'), true)
    require 'omf-web/content/repository'
    OMF::Web::ContentRepository.register_repo(:demo, :type => :file, :top_dir => File.join(File.dirname(__FILE__), 'repository'))


    Dir.glob("#{File.dirname(__FILE__)}/data_sources/*.rb").each do |fn|
      load fn
    end

    require 'yaml'
    Dir.glob("#{File.dirname(__FILE__)}/widgets/*.yaml").each do |fn|
      h = YAML.load_file(fn)
      if w = h['widget']
        OMF::Web.register_widget w
      else
        MObject.error "Don't know what to do with '#{fn}'"
      end
    end
  end
end

if __FILE__ == $0
  OmfWebDemo.start
end





