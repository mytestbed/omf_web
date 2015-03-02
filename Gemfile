source "http://rubygems.org"

# Specify your gem's dependencies in omf_web.gemspec
gemspec

def override_with_local(local_dir, opts = {})
  unless local_dir.start_with? '/'
    local_dir = File.join(File.dirname(__FILE__), local_dir)
  end
  #puts "Checking for '#{local_dir}'"
  Dir.exist?(local_dir) ? {path: local_dir} : opts
end

gem 'omf_oml', override_with_local('../omf_oml')
gem 'pg'
