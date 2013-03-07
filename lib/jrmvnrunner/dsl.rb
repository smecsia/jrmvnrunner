require 'sourcify'

module Jrmvnrunner
  class Dsl

    class Pom
      attr_reader :repositories
      attr_reader :dependencies

      def initialize
        @repositories = []
        @dependencies = []
      end

      def jar(path)
        path = path.split(':')
        @dependencies << {
            :group_id => path[0],
            :artifact_id => path[1],
            :version => path[2],
            :type => path[3] || 'jar',
            :classifier => path[4]
        }
      end

      def source(path)
        @repositories << {
            :name => path,
            :url => path,
        }
      end
    end

    class Gem
      attr_reader :source

      def initialize
        @source = ""
      end

      def source=(src)
        @source = src
      end
    end

    attr_reader :pom
    attr_reader :gem
    attr_reader :project_info

    def initialize
      @pom = Pom.new
      @gem = Gem.new
      @project_info = {:name => "jrmvnrunner", :version => '1.0'}
    end

    def Pomfile(code=nil, &block)
      if code
        @pom.instance_exec do
          eval(code)
        end
      else
        @pom.instance_exec(&block) if block_given?
      end
    end

    def Gemfile(code=nil, &block)
      if code
        @gem.source=code
      else
        @gem.source=block.to_ruby if block_given?
      end
    end

    def project(path)
      path = path.split(':')
      @project_info.merge!(
          :group_id => path[0],
          :name => path[1],
          :version => path[2]
      )
    end
  end
end