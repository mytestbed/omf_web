require 'find'
require 'omf_base/lobject'
require 'omf_web'
require 'omf-web/content/content_proxy'
require 'omf-web/content/repository'
require 'omf-web/content/gitolite'

module OMF::Web
  # This class provides an interface to a GIT repository served via Gitolite.
  #
  # To enable this in LW, provide the following configuration:
  #
  #    gitolite:
  #      admin_repo: git@localhost:gitolite-admin.git
  #      credentials:
  #        username: git
  #        publickey: /home/test/.ssh/bob.pub
  #        privatekey: /home/test/.ssh/bob
  #
  #    top_dir: git@localhost:test.git
  #    create_if_not_exists: true
  class GitoliteContentRepository < ContentRepository
    include OMF::Web::RuggedHelper

    WORKING_DIR_BASE = "/tmp/lw_repositories"

    attr_reader :name, :top_dir, :repo

    def initialize(name, opts)
      Gitolite.instance.setup(opts[:gitolite])
      super
      @repo = setup_repo(@top_dir, "#{WORKING_DIR_BASE}/#{name}", {})
    end

    def write(content_descr, content, message, opts = {})
      orig_content = read(content_descr)

      unless content == orig_content
        raise ReadOnlyContentRepositoryException.new if @read_only
        path = _get_path(content_descr)
        commit_content!(content, {
          path: path,
          message: message,
          author: opts[:author],
          committer: opts[:committer]
        })
        push!
      end
    end

    # Return the content of a given file
    def read(content_descr)
      fetch!
      path = _get_path(content_descr)
      read_blob(path)
    end

    # Return a URL for a path in this repo
    def get_url_for_path(path)
      @url_prefix + path
    end

    # Return an array of file names which are in the repository and
    # match 'search_pattern'
    def find_files(search_pattern, opts = {})
      fetch!
      search_pattern = Regexp.new(search_pattern)
      res = []
      unless @repo.empty?
        tree = @repo.head.target.tree
        _find_files(search_pattern, tree, nil, res)
      end
      res
    end

    def _find_files(search_pattern, tree, dir_path, res)
      tree.each do |v|
        d = v[:name]
        long_name = dir_path ? "#{dir_path}/#{d}" : d

        if v[:type] == :tree
          subtree = @repo.lookup(v[:oid])
          _find_files(search_pattern, subtree, long_name, res)
        else
          if long_name.match(search_pattern)
            mt = mime_type_for_file(d)
            path = long_name
            res << {
              path: path,
              url: get_url_for_path(path),
              name: d,
              mime_type: mt,
              #size: v.size,
              blob: v[:oid]
            }
          end
        end
      end
      res
    end

    protected

    def _create_if_not_exists
      Gitolite.instance.add_repo(@top_dir)
    end
  end # class
end # module
