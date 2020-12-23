# frozen_string_literal: true

require "dependabot/file_updaters"
require "dependabot/file_updaters/base"

module Dependabot
  module Pub
    class FileUpdater < Dependabot::FileUpdaters::Base
    end
  end
end

Dependabot::FileUpdaters.register("pub", Dependabot::Pub::FileUpdater)
