require 'stringio'

class RbenvWrapper < Jenkins::Tasks::BuildWrapper
  display_name "Rbenv build wrapper"

  RUBY_BUILD_PATH = "git://github.com/sstephenson/ruby-build.git"
  RBENV_PATH = "git://github.com/sstephenson/rbenv.git"

  attr_accessor :version

  def initialize(attrs = {})
    @version = attrs['version']
    @gem_list = attrs['gem_list']
  end

  def setup(build, launcher, listener)
    @launcher = launcher
    install_path = "$HOME/.rbenv/versions/#{@version}"

    unless directory_exists?("~/.rbenv")
      listener << "Install rbenv\n"
      launcher.execute("bash", "-c", "git clone #{RBENV_PATH} ~/.rbenv", {out: listener})
    end

    unless directory_exists?("~/.rbenv/plugins/ruby-build")
      listener << "Install ruby-build\n"
      launcher.execute("bash", "-c", "mkdir -p ~/.rbenv/plugins && cd ~/.rbenv/plugins && git clone #{RUBY_BUILD_PATH}", {out: listener})
    end

    unless directory_exists?(install_path)
      listener << "Install #{@version}\n"
      launcher.execute("bash", "-c", "~/.rbenv/bin/rbenv install #{@version}", {out: listener})
    end

    list = StringIO.new
    launcher.execute("bash", "-c", "#{install_path}/bin/gem list", {out: list})
    (@gem_list || 'bundler,rake').split(',').each do |gem|
      unless list.string.include? gem
        listener << "Install #{gem}\n"
        launcher.execute("bash", "-c", "#{install_path}/bin/gem install #{gem}", {out: listener})
      end
    end

    build.env['RBENV_VERSION'] = @version
    build.env['PATH+RBENV'] = "#{install_path}/bin"
  end

  def directory_exists?(path)
    @launcher.execute("bash", "-c", "test -d #{path}") == 0
  end
end
