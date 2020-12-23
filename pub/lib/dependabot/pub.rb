# frozen_string_literal: true

require "dependabot/pub/file_fetcher"
require "dependabot/pub/file_parser"
require "dependabot/pub/file_updater"
require "dependabot/pub/metadata_finder"
require "dependabot/pub/requirement"
require "dependabot/pub/update_checker"
require "dependabot/pub/version"

require "dependabot/pull_request_creator/labeler"
Dependabot::PullRequestCreator::Labeler.
  register_label_details("pub", name: "pub", colour: "0175C2")

require "dependabot/dependency"
Dependabot::Dependency.
  register_production_check("pub", ->(_) { true })
