# frozen_string_literal: true

require "dependabot/file_fetchers"
require "dependabot/file_fetchers/base"

module Dependabot
  module Pub
    class FileFetcher < Dependabot::FileFetchers::Base
    end
  end
end

Dependabot::FileFetchers.register("pub", Dependabot::Pub::FileFetcher)
