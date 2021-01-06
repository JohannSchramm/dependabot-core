# frozen_string_literal: true

require "dependabot/file_fetchers"
require "dependabot/file_fetchers/base"

module Dependabot
  module Pub
    class FileFetcher < Dependabot::FileFetchers::Base
      def self.required_files_in?(filenames)
        filenames.include?("pubspec.yaml")
      end

      def self.required_files_message
        "Directory must contain a pubspec.yaml"
      end

      private

      def fetch_files
        files = []

        files << pubspec if pubspec

        return files if files.any?

        path = Pathname.new(File.join(directory, "pubspec.yaml")).cleanpath.to_path
        raise Dependabot::DependencyFileNotFound, path
      end

      def pubspec
        @pubspec ||= fetch_file_if_present("pubspec.yaml")
      end
    end
  end
end

Dependabot::FileFetchers.register("pub", Dependabot::Pub::FileFetcher)
