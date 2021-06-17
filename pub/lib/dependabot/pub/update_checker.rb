# frozen_string_literal: true

require "excon"
require "dependabot/update_checkers"
require "dependabot/update_checkers/base"
require "dependabot/pub/version"
require "dependabot/pub/requirement"

module Dependabot
  module Pub
    class UpdateChecker < Dependabot::UpdateCheckers::Base
      def latest_version
        all_package_versions.max { |a, b| a.priority b }
      end

      def latest_resolvable_version
        all_package_versions.select { |ver| pub_requirements.all? { |req| req.satisfied_by?(ver) } }.
          max { |a, b| a.priority b }
      end

      def updated_requirements
        dependency.requirements.map do |req|
          new_requirement = "^#{latest_version.version}"
          req.merge(requirement: new_requirement)
        end
      end

      def latest_resolvable_version_with_no_unlock
        latest_resolvable_version
      end

      def up_to_date?
        return true if pub_requirements.any?(&:any_op?)

        super
      end

      private

      def latest_version_resolvable_with_full_unlock?
        false
      end

      def updated_dependencies_after_full_unlock
        raise NotImplementedError
      end

      def all_package_versions
        return @all_versions unless @all_versions.nil?

        res = Excon.get(
          "https://pub.dartlang.org/packages/#{dependency.name}.json",
          idempotent: true,
          **Dependabot::SharedHelpers.excon_defaults
        )

        return [] unless res.status == 200

        @all_versions = JSON.parse(res.body)["versions"].map { |v| Dependabot::Pub::Version.new(v) }
      end

      def pub_requirements
        dependency.requirements.map { |req| Dependabot::Pub::Requirement.new(req[:requirement]) }
      end
    end
  end
end

Dependabot::UpdateCheckers.register("pub", Dependabot::Pub::UpdateChecker)
