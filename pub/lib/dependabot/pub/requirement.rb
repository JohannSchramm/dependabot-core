# frozen_string_literal: true

require "dependabot/utils"

module Dependabot
  module Pub
    class Requirement < Gem::Requirement
    end
  end
end

Dependabot::Utils.register_requirement_class("pub", Dependabot::Pub::Requirement)
