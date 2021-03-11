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

        pubspec_files.each do |file|
          set += pubspec_file_dependencies(file)
        end

        set.dependencies
      end

      private

      def check_required_files
        return if get_original_file("pubspec.yaml")

        raise "No pubspec.yaml file"
      end

      def dependency_strings_from_yaml(yaml, group)
        data = YAML.safe_load(yaml.content, aliases: true)

        dependencies = data.fetch(group, {})

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
          set << Dependency.new(
            name: dependency[:name],
            version: (dependency[:requires] if exact_version?(dependency[:requires])),
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

      def exact_version?(req)
        Dependabot::Pub::Requirement.new(req).exact?
      end

      def pubspec_files
        dependency_files
      end
    end
  end
end

Dependabot::FileParsers.register("pub", Dependabot::Pub::FileParser)
