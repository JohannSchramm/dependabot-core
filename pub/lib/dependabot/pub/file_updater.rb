# frozen_string_literal: true

require "dependabot/file_updaters"
require "dependabot/file_updaters/base"

module Dependabot
  module Pub
    class FileUpdater < Dependabot::FileUpdaters::Base
      def self.updated_files_regex
        [/pubspec\.yaml/.freeze]
      end

      def updated_dependency_files
        updated = []

        dependency_files.each do |file|
          dependencies.each do |dep|
            next unless requirement_changed?(file, dep)

            updated << updated_dependency_for_file(file, dep)
          end
        end

        updated
      end

      private

      def check_required_files
        return if get_original_file("pubspec.yaml")

        raise "No pubspec.yaml file"
      end

      def updated_dependency_for_file(file, dependency)
        name = Regexp.escape(dependency.name)
        requirement = Regexp.escape(build_requirement_string(dependency.previous_requirements))

        regex = /(#{name}:)\s*((#{requirement})|('#{requirement}')|("#{requirement}"))/m.freeze

        new_requirement = yaml_requirement_string(changed_requirements(dependency))
        replace = "#{name}: #{new_requirement}"
        updated_content = file.content.gsub(regex, replace)

        updated_file(
          file: file,
          content: updated_content
        )
      end

      def build_requirement_string(requirements)
        requirements.reduce("") { |acc, el| "#{acc} #{el[:requirement]}" }.strip
      end

      def yaml_requirement_string(requirements)
        special = /[<>=]/.freeze

        requirement = build_requirement_string(requirements)
        res = special.match(requirement)

        return "'#{requirement}'" unless res.nil?

        requirement
      end

      def changed_requirements(dependency)
        dependency.requirements - dependency.previous_requirements
      end
    end
  end
end

Dependabot::FileUpdaters.register("pub", Dependabot::Pub::FileUpdater)
