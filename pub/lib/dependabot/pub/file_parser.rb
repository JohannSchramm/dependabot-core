# frozen_string_literal: true

require "dependabot/file_parsers"
require "dependabot/file_parsers/base"

module Dependabot
  module Pub
    class FileParser < Dependabot::FileParsers::Base
    end
  end
end

Dependabot::FileParsers.register("pub", Dependabot::Pub::FileParser)
