begin
  require 'rugged'
rescue LoadError => e
  puts <<-ERR
#{e.message}

# To use gitolite support, please install GEM 'rugged'
#
#   gem install rugged
#
# See (https://github.com/libgit2/rugged) for more details
  ERR
  exit(1)
end

require 'omf_web'
require 'omf_base/lobject'

module OMF::Web
  module RuggedHelper
    def default_git_opts
      { credentials: Gitolite.instance.credentials }
    end

    def setup_repo(url, working_dir, opts = {})
      begin
        Rugged::Repository.new(working_dir)
      rescue Rugged::OSError
        Rugged::Repository.clone_at(url, working_dir, opts.merge(default_git_opts))
      end
    end

    def fetch!(opts = {})
      repo.fetch("origin", nil, opts.merge(default_git_opts))
    end

    def push!(opts = {})
      repo.push("origin", ["refs/heads/master"], opts.merge(default_git_opts))
    end

    def read_blob(path)
      return if repo.empty?
      blob = repo.blob_at(repo.head.target.oid, path)
      blob && blob.content
    end

    # Write content into a blob object, stage it and commit
    def commit_content!(content, opts = {})
      oid = repo.write(content, :blob)

      index = repo.index
      index.read_tree(repo.head.target.tree) unless repo.empty?

      # FIXME What should mode be?
      index.add(path: opts[:path], oid: oid, mode: 0100644)

      # Author &|| committer shall contains :email and :name
      author = opts[:author] || { email: "admin@labwiki.com", name: "LabWiki Robot" }
      committer = opts[:committer] || author
      message = opts[:message] || "New commit via LabWiki"

      Rugged::Commit.create(@repo, {
        tree: index.write_tree(repo),
        author: author.merge(time: Time.now),
        committer: committer.merge(time: Time.now),
        message: message,
        parents: repo.empty? ? [] : [ repo.head.target ].compact,
        update_ref: 'HEAD'
      })
    end
  end

  class Gitolite < OMF::Base::LObject
    include Singleton
    include OMF::Web::RuggedHelper

    WORKING_DIR = "/tmp/gitolite-admin"

    attr_reader :credentials, :repo

    def initialize
      super
    end

    def setup(opts)
      @credentials = Rugged::Credentials::SshKey.new(opts[:credentials])
      @repo = setup_repo(opts[:admin_repo], WORKING_DIR, { bare: true })
    end

    # Adding a new repository for the end user
    #
    # * Allow RW+ for the end user
    # * Allow RW+ for the gitolite admin
    # * Repository name will be identical to the end user id
    def add_repo(id)
      # Append repo setup to gitolite.conf
      if id =~  /^.+@.+:(.+)\.git$/
        return if repo_exists?($1)
        new_conf = read_blob("conf/gitolite.conf") +
          "\nrepo #{$1}\n    RW+     =   @all\n    RW+     =   gitolite-admin\n\n"
        commit_content!(new_conf, path: "conf/gitolite.conf", message: "Added repo #{id}")
        push!

        # TODO Add keys
      else
        raise StandardError, "Malformed repository url '#{id}'"
      end
    end

    # Adding a new public key for the user
    def add_key(id, key)
      push!
    end

    def repo_exists?(id)
      fetch!
      read_blob("conf/gitolite.conf") =~ /repo #{id}/
    end
  end
end
