# frozen_string_literal: true

require_relative "match_platform"

module Bundler
  class LazySpecification
    Identifier = Struct.new(:name, :version, :source, :platform, :dependencies)
    class Identifier
      include Comparable
      def <=>(other)
        return unless other.is_a?(Identifier)
        [name, version, platform_string] <=> [other.name, other.version, other.platform_string]
      end

      protected

      def platform_string
        platform_string = platform.to_s
        platform_string == Index::RUBY ? Index::NULL : platform_string
      end
    end

    include MatchPlatform

    attr_reader :name, :version, :dependencies, :platform
    attr_accessor :source, :remote

    def initialize(name, version, platform, source = nil)
      @name          = name
      @version       = version
      @dependencies  = []
      @platform      = platform || Gem::Platform::RUBY
      @source        = source
      @specification = nil
    end

    def full_name
      if platform == Gem::Platform::RUBY || platform.nil?
        "#{@name}-#{@version}"
      else
        "#{@name}-#{@version}-#{platform}"
      end
    end

    def ==(other)
      identifier == other.identifier
    end

    def eql?(other)
      identifier.eql?(other.identifier)
    end

    def hash
      identifier.hash
    end

    def satisfies?(dependency)
      @name == dependency.name && dependency.requirement.satisfied_by?(Gem::Version.new(@version))
    end

    def to_lock
      out = String.new

      if platform == Gem::Platform::RUBY || platform.nil?
        out << "    #{name} (#{version})\n"
      else
        out << "    #{name} (#{version}-#{platform})\n"
      end

      dependencies.sort_by(&:to_s).uniq.each do |dep|
        next if dep.type == :development
        out << "    #{dep.to_lock}\n"
      end

      out
    end

    def __materialize__
      @specification = if source.is_a?(Source::Gemspec) && source.gemspec.name == name
        source.gemspec.tap {|s| s.source = source }
      else
        search_object = if source.is_a?(Source::Path)
          Dependency.new(name, version)
        else
          locked_bundler_version = Bundler.locked_bundler_version

          if locked_bundler_version && Gem::Version.new(locked_bundler_version) < Gem::Version.new("2.2.0")
            Dependency.new(name, version)
          else
            self
          end
        end
        STDOUT.puts "search_object: #{search_object}"
        platform_object = Gem::Platform.new(platform)
        STDOUT.puts "source.specs: #{source.specs.map(&:full_name)}"
        candidates = source.specs.search(search_object)
        STDOUT.puts "candidates: #{candidates.map(&:full_name)}"
        STDOUT.puts "source.specs.local_search(search_object): #{source.specs.local_search(search_object).map(&:full_name)}"
        STDOUT.puts "source.specs.send(:specs_by_name, name): #{source.specs.send(:specs_by_name, name).map(&:full_name)}"
        same_platform_candidates = candidates.select do |spec|
          MatchPlatform.platforms_match?(spec.platform, platform_object)
        end
        STDOUT.puts "same_platform_candidates.map(&:full_name): #{same_platform_candidates.map(&:full_name)}"
        search = same_platform_candidates.last || candidates.last
        search.dependencies = dependencies if search && (search.is_a?(RemoteSpecification) || search.is_a?(EndpointSpecification))
        search
      end
    end

    def respond_to?(*args)
      super || @specification ? @specification.respond_to?(*args) : nil
    end

    def to_s
      @__to_s ||= if platform == Gem::Platform::RUBY || platform.nil?
        "#{name} (#{version})"
      else
        "#{name} (#{version}-#{platform})"
      end
    end

    def identifier
      @__identifier ||= Identifier.new(name, version, source, platform, dependencies)
    end

    def git_version
      return unless source.is_a?(Bundler::Source::Git)
      " #{source.revision[0..6]}"
    end

    private

    def to_ary
      nil
    end

    def method_missing(method, *args, &blk)
      raise "LazySpecification has not been materialized yet (calling :#{method} #{args.inspect})" unless @specification

      return super unless respond_to?(method)

      @specification.send(method, *args, &blk)
    end
  end
end