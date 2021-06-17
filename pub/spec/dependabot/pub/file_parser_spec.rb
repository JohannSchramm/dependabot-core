# frozen_string_literal: true

require "spec_helper"
require "dependabot/pub/file_parser"
require_common_spec "file_parsers/shared_examples_for_file_parsers"

RSpec.describe Dependabot::Pub::FileParser do
  it_behaves_like "a dependency file parser"

  let(:files) { [pubspec_file] }

  let(:source) do
    Dependabot::Source.new(
      provider: "github",
      repo: "JohannSchramm/dependabot-pub-example",
      directory: "/"
    )
  end

  let(:file_parser_instance) do
    described_class.new(dependency_files: files, source: source)
  end

  context "parse" do
    subject(:dependencies) { file_parser_instance.parse }

    context "with a valid pubspec.yaml" do
      let(:pubspec_file) do
        Dependabot::DependencyFile.new(
          name: "pubspec.yaml",
          content: fixture("pubspec", "valid_pubspec.yaml")
        )
      end

      mock_dependencies = [
        Dependabot::Dependency.new(
          name: "a",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: "1.0.0",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        ),
        Dependabot::Dependency.new(
          name: "b",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: ">= 1.0.0",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        ),
        Dependabot::Dependency.new(
          name: "c",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: "> 1.0.0",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        ),
        Dependabot::Dependency.new(
          name: "d",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: "<= 1.0.0",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        ),
        Dependabot::Dependency.new(
          name: "e",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: "< 1.0.0",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        ),
        Dependabot::Dependency.new(
          name: "f",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: "any",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        ),
        Dependabot::Dependency.new(
          name: "g",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: "^1.0.0",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        ),
        Dependabot::Dependency.new(
          name: "h",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: ">= 1.0.0 < 2.0.0",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        ),
        Dependabot::Dependency.new(
          name: "i",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: "<= 1.1.2 > 1.1.0",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        ),
        Dependabot::Dependency.new(
          name: "j",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: ">=0.1.0-a.0 <2.0.0",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        ),
        Dependabot::Dependency.new(
          name: "z",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: "1.0.0",
            groups: ["dev_dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        )
      ]

      mock_dependencies.each do |dependency|
        it "should contain #{dependency}" do
          found = dependencies.find { |d| d.name == dependency.name }
          expect(found).to eq(dependency)
        end
      end

      it "should contain exactly #{mock_dependencies.length} dependencies" do
        expect(dependencies.length).to eq(mock_dependencies.length)
      end
    end

    context "with an invalid pubspec.yaml" do
      let(:pubspec_file) do
        Dependabot::DependencyFile.new(
          name: "pubspec.yaml",
          content: fixture("pubspec", "invalid_pubspec.yaml")
        )
      end

      it "should throw an error" do
        expect { file_parser_instance.parse }.to raise_error(
          Dependabot::DependencyFileNotParseable
        )
      end
    end

    context "with an invalid yaml" do
      let(:pubspec_file) do
        Dependabot::DependencyFile.new(
          name: "pubspec.yaml",
          content: fixture("pubspec", "invalid_yaml.yaml")
        )
      end

      it "should throw an error" do
        expect { file_parser_instance.parse }.to raise_error(
          Dependabot::DependencyFileNotParseable
        )
      end
    end

    context "with an empty pubspec.yaml" do
      let(:pubspec_file) do
        Dependabot::DependencyFile.new(
          name: "pubspec.yaml",
          content: ""
        )
      end

      it "should return no dependencies" do
        expect(dependencies.length).to eq(0)
      end
    end

    context "without pubspec.yaml" do
      let(:files) { [] }

      it "should throw an error" do
        expect { file_parser_instance.parse }.to raise_error(
          "No pubspec.yaml file"
        )
      end
    end
  end
end
