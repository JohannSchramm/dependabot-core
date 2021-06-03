# frozen_string_literal: true

require "dependabot/shared_helpers"
require "dependabot/file_updaters"
require "dependabot/file_updaters/base"

module Dependabot
  module Pub
    class FileUpdater < Dependabot::FileUpdaters::Base
      def self.updated_files_regex
        [/pubspec\.yaml/.freeze, /pubspec\.lock/.freeze]
      end

      def updated_dependency_files
        updated = []

        unless pubspec.nil?
          dependencies.each do |dep|
            next unless requirement_changed?(pubspec, dep)

            spec = updated_dependency_for_file(pubspec, dep)
            updated << spec

            updated << updated_lockfile_for_pubspec_dependency(spec, dep) unless lockfile.nil?
          end
        end

        updated
      end

      private

      def pubspec
        get_original_file("pubspec.yaml")
      end

      def lockfile
        get_original_file("pubspec.lock")
      end

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

      def updated_lockfile_for_pubspec_dependency(spec, dependency)
        SharedHelpers.in_a_temporary_directory(spec.directory) do
          File.write("pubspec.yaml", spec.content)

          SharedHelpers.run_shell_command("dart pub upgrade #{dependency.name}")

          updated_file(
            file: lockfile,
            content: File.read("pubspec.lock")
          )
        end
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
