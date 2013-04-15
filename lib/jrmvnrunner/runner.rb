require 'pathname'
require 'tempfile'
require 'tmpdir'
require 'securerandom'
require 'yaml'

module Jrmvnrunner
  class Runner
    def initialize(cmd = nil, opts={})
      @args = opts[:args] || []
      @opts = opts
      @pom = opts[:pom] || Dsl::Pom.new
      @gem = opts[:gem] || Dsl::Gem.new
      @root = opts[:root] || root
      @cmd = cmd
      @tmpdir = opts[:tmpdir]
      @config = YAML::load(File.read(cfg_file)) if File.exists?(cfg_file)
      @config ||= {}
      @opts[:project] ||= {:group_id => 'test', :artifact_id => 'test', :version => '0.1-SNAPSHOT'}
    end

    def execute!
      log "Current directory: #{Dir.pwd}"

      if cached_dir.nil? || !File.exists?(cached_dir)
        ensure_jruby!
        ensure_mvn!
        write_gem!
        ensure_bundle!
        write_pom!
        maven_build!
        create_cache_file!
      else
        @tmpdir = cached_dir
      end

      if @cmd
        # Generating command and exec...
        ensure_cmd!
        cmd=%Q["#{cmd_path("jruby")}" #{cp_string} #{jruby_opts} "#{cmd_path(@cmd)}" #{@args.join(" ")}]
        log "Executing '#{cmd}'..."
        exec cmd
      else
        require 'java'
        ENV['BUNDLE_GEMFILE'] = gem_file
        require 'bundler'
        Bundler.definition.validate_ruby!
        Bundler.load.setup_environment
        jar_files.each { |jf| require jf }
      end
    end

    def clean_cache!
      File.unlink(cache_file) if File.exists?(cache_file)
    end

    private

    def cfg_file
      root.join("config", "adapter.yml")
    end

    def which_cmd
      windows? ? "where" : "which"
    end

    def jruby_opts
      @opts[:jruby_opts] || "--1.9"
    end

    def windows?
      @opts[:platform] == "windows"
    end

    def root
      @root ||= Pathname.new(File.expand_path(File.join(File.dirname(__FILE__), '..')))
      @root
    end

    def cp_join_sign
      windows? ? ";" : ":"
    end

    def cmd_path(cmd)
      @config["#{cmd}.bin"] || `#{which_cmd} #{cmd}`.split("\n").select { |l| !l.nil? && !l.empty? }.first
    end

    def cp_string
      # Searching through dependent jars
      cp = jar_files.join(cp_join_sign)
      %Q{-J-cp "#{cp}"}
    end

    def cache_file
      root.join(".Jrmvnrunner.cache")
    end

    def cached_dir
      (File.exists?(cache_file)) ? File.read(cache_file).strip : nil
    end

    def create_cache_file!
      File.open(cache_file, "w+") do |f|
        f.write(tmpdir)
      end
    end

    def jar_files
      Dir[Pathname.new(build_dir).join("#{@opts[:project][:name]}", "*.jar")]
    end

    def gems_list
      `"#{cmd_path("jgem")}" list`
    end

    def ensure_cmd!
      raise "Cannot find command '#{@cmd}': (tried '#{which_cmd} #{@cmd}')!" if cmd_path(@cmd).nil?
    end

    def ensure_jruby!
      raise "Cannot find valid JRuby installation (tried command '#{which_cmd} jruby')!" if cmd_path("jruby").nil?
    end

    def ensure_mvn!
      # Building Maven dependencies...
      raise "Cannot find valid Maven installation (tried command '#{which_cmd} mvn')!" if cmd_path("mvn").nil?
    end

    def ensure_bundle!
      unless gems_list =~ /bundler/
        log "Installing bundler..."
        res = `"#{cmd_path("jgem")}" install bundler`
        raise "Cannot install bundler: \n #{res}" unless res =~ /Successfully installed bundler/
      end
      log "Installing bundle..."
      res = `"#{cmd_path("bundle")}" install --gemfile #{gem_file}`
      raise "Cannot install bundle: \n #{res}" unless res =~ /Your bundle is complete!/
    end

    def maven_build!
      log "Building dependencies..."
      build_res = `"#{cmd_path("mvn")}" -f #{pom_file} clean install`
      raise "Cannot build project: \n #{build_res}" unless build_res =~ /BUILD SUCCESS/
    end

    def log(msg)
      puts msg
    end

    def gem
      @gem
    end

    def pom
      @pom
    end

    def gem_file
      @gem_file ||= Pathname.new(tmpdir).join('Gemfile').to_s
      @gem_file
    end

    def pom_file
      @pom_file ||= Pathname.new(tmpdir).join('pom.xml').to_s
      @pom_file
    end

    def tmpdir
      @tmpdir ||= Pathname.new(Etc.systmpdir).join(SecureRandom.hex(5)).to_s
      FileUtils.mkdir_p(@tmpdir)
      @tmpdir
    end

    def build_dir
      @builddir ||= Pathname.new(tmpdir).join('target').to_s
      @builddir
    end

    def generate_gem
      @gem.source
    end

    def write_gem!
      log "Writing temporary Gemfile: #{gem_file}"
      File.open(gem_file, "w+") do |f|
        f.write(generate_gem)
      end
    end

    def write_pom!
      log "Writing temporary Pomfile: #{pom_file}"
      File.open(pom_file, "w+") do |f|
        f.write(generate_pom)
      end
    end

    def generate_pom
      <<-XML
<?xml version="1.0" encoding="UTF-8"?>
  <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>#{@opts[:project][:group_id]}</groupId>
    <artifactId>#{@opts[:project][:name]}</artifactId>
    <version>#{@opts[:project][:version]}</version>
    <packaging>ear</packaging>

    <properties>
        <project.compiler.version>1.6</project.compiler.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <repositories>
        #{
      pom.repositories.map do |r|
        %Q[
            <repository>
                <id>#{r[:name]}</id>
                <name>#{r[:description]}</name>
                <url>#{r[:url]}</url>
            </repository>
          ]
      end.join("\n")
      }
    </repositories>

    <dependencies>
        #{
      pom.dependencies.map do |d|
        %Q[
        <dependency>
            <groupId>#{d[:group_id]}</groupId>
            <artifactId>#{d[:artifact_id]}</artifactId>
            <version>#{d[:version]}</version>
            <type>#{d[:type]}</type>
            #{ (d[:classifier]) ? "<classifier>#{d[:classifier]}</classifier>" : ""}
        </dependency>
        ]
      end.join("\n")
      }
    </dependencies>
    <build>
        <finalName>#{@opts[:project][:name]}</finalName>
        <directory>#{build_dir}</directory>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>2.3.2</version>
                <configuration>
                    <encoding>${project.build.sourceEncoding}</encoding>
                    <source>${project.compiler.version}</source>
                    <target>${project.compiler.version}</target>
                    <optimize>true</optimize>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
      XML
    end
  end
end
