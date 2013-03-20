require 'pathname'

module Jrmvnrunner
  VERSION="0.1.4"
  MYDIR = Pathname.new(File.dirname(File.expand_path(__FILE__)))
  autoload :Runner, MYDIR.join('jrmvnrunner/runner')
  autoload :Dsl, MYDIR.join('jrmvnrunner/dsl')

  def self.install!(wdir = Dir.pwd)
    root = Pathname.new(wdir)
    runnerfile = root.join("Jrmvnrunner")
    if File.exists?(runnerfile)
      runner = init_runner(root, runnerfile)
      runner.clean_cache!
      runner.execute!
    end
  end

  def self.init!(wdir = Dir.pwd, cmd = nil, args = [])
    raise "Jrmvnrunner has been already started!" if @__init_called
    @__init_called = true
    root = Pathname.new(wdir)
    runnerfile = root.join("Jrmvnrunner")
    if File.exists?(runnerfile)
      runner = init_runner(root, runnerfile, cmd, args)
      runner.execute!
    end
  end

  private

  def self.init_runner(root = Dir.pwd, runnerfile = root.join("Jrmvnrunner"), cmd = nil, args = [])
    dsl = Dsl.new
    runner_conf = File.read(runnerfile)

    dsl.instance_exec do
      eval(runner_conf.match(/(project .+)\n/)[1])
    end

    dsl.Pomfile(runner_conf.match(/Pomfile\s+do\s(.+?)end/m)[1])
    dsl.Gemfile(runner_conf.match(/Gemfile\s+do\s(.+?)end/m)[1])
    Runner.new(cmd, {
        :gem => dsl.gem,
        :pom => dsl.pom,
        :project => dsl.project_info,
        :root => root,
        :args => args
    })
  end
end
