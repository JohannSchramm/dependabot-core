# frozen_string_literal: true

require "dependabot/utils"

module Dependabot
  module Pub
    class Version < Gem::Version
      attr_reader :version_number_string, :prerelease_string, :build_number_string

      VERSION_NUMBER_PATTERN = "\\d+\\.\\d+.\\d+"
      SUFFIX_PATTERN = "[-a-zA-Z0-9]+(\\.[-a-zA-Z0-9]+)*"
      PRERELEASE_PATTERN = "-#{SUFFIX_PATTERN}"
      BUILD_NUMBER_PATTERN = "\\+#{SUFFIX_PATTERN}"

      VERSION_REGEX = /\A#{VERSION_NUMBER_PATTERN}(#{PRERELEASE_PATTERN})?(#{BUILD_NUMBER_PATTERN})?\Z/.freeze
      VERSION_NUMBER_REGEX = /#{VERSION_NUMBER_PATTERN}/.freeze
      PRERELEASE_REGEX = /#{PRERELEASE_PATTERN}/.freeze
      BUILD_NUMBER_REGEX = /#{BUILD_NUMBER_PATTERN}/.freeze

      def initialize(version)
        raise ArgumentError, "Malformed version string #{version}" unless self.class.correct?(version)

        @version_string = version.to_s
        @version_number_string = @version_string.match(VERSION_NUMBER_REGEX)[0]

        @contains_buildnumber = @version_string.include?("+")
        @build_number_string = @version_string.match(BUILD_NUMBER_REGEX)[0][1..-1] if @contains_buildnumber

        temp_prerelease_string = @contains_buildnumber ? @version_string.split("+")[0] : @version_string
        @contains_prerelease = temp_prerelease_string.include?("-")
        @prerelease_string = temp_prerelease_string.match(PRERELEASE_REGEX)[0][1..-1] if @contains_prerelease

        version = @version_number_string
        super
      end

      def self.correct?(version)
        version.to_s.match?(VERSION_REGEX)
      end

      def version
        @version_string
      end

      def <=>(other)
        comparison = super(other)
        return comparison unless comparison.zero? && other.is_a?(Dependabot::Pub::Version)

        comparison = compare_is_prerelease(other)
        return comparison unless comparison.nil? || comparison.zero?

        comparison = compare_has_build_number(other)
        return comparison unless comparison.nil? || comparison.zero?

        comparison = compare_suffix(prerelease_string, other.prerelease_string)
        return comparison unless comparison.zero?

        compare_suffix(build_number_string, other.build_number_string)
      end

      private

      def zip_unknown_length(list_a, list_b)
        difference = list_b.length - list_a.length
        list_a += [nil] * difference if difference.positive?

        list_a.zip(list_b)
      end

      def compare_is_prerelease(other)
        return -1 if !prerelease_string.nil? && other.prerelease_string.nil?
        return 1 if prerelease_string.nil? && !other.prerelease_string.nil?
      end

      def compare_has_build_number(other)
        return 1 if !build_number_string.nil? && other.build_number_string.nil?
        return -1 if build_number_string.nil? && !other.build_number_string.nil?
      end

      def compare_suffix(element_a, element_b)
        return 0 if element_a.nil? && element_b.nil?

        compare_identifier_list(element_a.split("."), element_b.split("."))
      end

      def compare_identifier_list(list_a, list_b)
        elements = zip_unknown_length(list_a, list_b).
                   filter { |a, b| a != b }.
                   flatten

        return 0 if elements.length < 2

        compare_identifiers(elements[0], elements[1])
      end

      def compare_identifiers(element_a, element_b)
        return -1 if element_a.nil?
        return 1 if element_b.nil?

        return element_a.to_i <=> element_b.to_i if element_a.match(/\A\d+\Z/) && element_b.match(/\A\d+\Z/)
        return -1 if element_a.match(/\A\d+\Z/)
        return 1 if element_b.match(/\A\d+\Z/)

        element_a <=> element_b
      end
    end
  end
end

Dependabot::Utils.register_version_class("pub", Dependabot::Pub::Version)
