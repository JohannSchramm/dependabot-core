# frozen_string_literal: true

require "dependabot/metadata_finders"
require "dependabot/metadata_finders/base"

module Dependabot
  module Pub
    class MetadataFinder < Dependabot::MetadataFinders::Base
      private

      def look_up_source
        pubspec = package_info["latest"]["pubspec"]
        repo = pubspec["homepage"] unless pubspec["homepage"].nil?
        repo = pubspec["repository"] unless pubspec["repository"].nil?
        Source.from_url(repo)
      end

      def package_info
        res = Excon.get(
          "https://pub.dartlang.org/api/packages/#{dependency.name}",
          idempotent: true,
          **Dependabot::SharedHelpers.excon_defaults
        )

        raise "Unable to get package info" unless res.status == 200

        JSON.parse(res.body)
      end
    end
  end
end

Dependabot::MetadataFinders.register("pub", Dependabot::Pub::MetadataFinder)
