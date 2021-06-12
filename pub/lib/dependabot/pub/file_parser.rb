# frozen_string_literal: true

require "dependabot/dependency"
require "dependabot/file_parsers"
require "dependabot/file_parsers/base"
require "dependabot/pub/requirement"

module Dependabot
  module Pub
    class FileParser < Dependabot::FileParsers::Base
      require "dependabot/file_parsers/base/dependency_set"

      def parse
        set = DependencySet.new

        set += pubspec_file_dependencies(pubspec) unless pubspec.nil?

        set.dependencies
      end

      private

      def pubspec
        get_original_file("pubspec.yaml")
      end

      def check_required_files
        return if pubspec

        raise "No pubspec.yaml file"
      end

      def dependency_strings_from_yaml(yaml, group)
        data = YAML.safe_load(yaml.content, aliases: true)

        dependencies = data.fetch(group, {})

        return [] if dependencies.nil?

        dependencies.
          select { |_, value| value.is_a?(String) }.
          map { |key, val| { name: key, requires: val, group: group } }
      rescue Psych::SyntaxError
        raise Dependabot::DependencyFileNotParseable, yaml.name
      end

      def pubspec_file_dependencies(file)
        set = DependencySet.new

        dependencies = dependency_strings_from_yaml(file, "dependencies")
        dev_dependencies = dependency_strings_from_yaml(file, "dev_dependencies")
        all = [dependencies, dev_dependencies].flatten

        all.each do |dependency|
          Dependabot::Pub::Requirement.new(dependency[:requires])

          set << Dependency.new(
            name: dependency[:name],
            version: nil,
            package_manager: "pub",
            requirements: [{
              requirement: dependency[:requires],
              groups: [dependency[:group]],
              source: nil,
              file: "pubspec.yaml"
            }]
          )
        end

        set
      rescue Gem::Requirement::BadRequirementError
        raise Dependabot::DependencyFileNotParseable, file.name
      end
    end
  end
end

Dependabot::FileParsers.register("pub", Dependabot::Pub::FileParser)
