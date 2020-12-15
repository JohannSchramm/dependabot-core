# frozen_string_literal: true

require "dependabot/pull_request_creator/labeler"
Dependabot::PullRequestCreator::Labeler.
  register_label_details("pub", name: "pub", colour: "0175C2")

require "dependabot/dependency"
Dependabot::Dependency.
  register_production_check("pub", ->(_) { true })

module Dependabot
  class Pub
  end
end
