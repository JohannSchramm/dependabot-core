# frozen_string_literal: true

require "spec_helper"
require "dependabot/shared_helpers"
require "dependabot/pub/file_updater"
require_common_spec "file_updaters/shared_examples_for_file_updaters"

RSpec.describe Dependabot::Pub::FileUpdater do
  it_behaves_like "a dependency file updater"

  let(:credentials) do
    [{
      "type" => "git_source",
      "host" => "github.com",
      "username" => "x-access-token",
      "password" => "token"
    }]
  end
  let(:file_updater_instance) do
    described_class.new(
      dependencies: dependencies,
      dependency_files: dependency_files,
      credentials: credentials
    )
  end

  context "for a pubspec.yaml and a pubspec.lock file" do
    subject(:updated_files) { file_updater_instance.updated_dependency_files }

    context "with a dependency" do
      let(:dependencies) do
        [
          Dependabot::Dependency.new(
            name: "a",
            version: nil,
            package_manager: "pub",
            requirements: [{
              requirement: "^2.1.0",
              groups: ["dependencies"],
              source: nil,
              file: "pubspec.yaml"
            }],
            previous_version: nil,
            previous_requirements: [{
              requirement: "^1.0.0",
              groups: ["dependencies"],
              source: nil,
              file: "pubspec.yaml"
            }]
          )
        ]
      end

      let(:dependency_files) do
        [
          Dependabot::DependencyFile.new(
            name: "pubspec.yaml",
            content: fixture("pubspec", "outdated_pubspec.yaml")
          ),
          Dependabot::DependencyFile.new(
            name: "pubspec.lock",
            content: "test pubspec.lock content"
          )
        ]
      end

      it "should update the dependency and lockfile" do
        expect(Dependabot::SharedHelpers).to receive(:run_shell_command).with("dart pub upgrade a")

        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with("pubspec.lock").and_return("updated pubspec.lock content")

        expected_files = [
          Dependabot::DependencyFile.new(
            name: "pubspec.yaml",
            content: fixture("pubspec", "updated_pubspec.yaml")
          ),
          Dependabot::DependencyFile.new(
            name: "pubspec.lock",
            content: "updated pubspec.lock content"
          )
        ]
        expect(updated_files).to eq(expected_files)
      end
    end
  end

  context "for a pubspec.yaml file" do
    subject(:updated_files) { file_updater_instance.updated_dependency_files }

    context "with a dependency" do
      let(:dependencies) do
        [
          Dependabot::Dependency.new(
            name: "a",
            version: nil,
            package_manager: "pub",
            requirements: [{
              requirement: "^2.1.0",
              groups: ["dependencies"],
              source: nil,
              file: "pubspec.yaml"
            }],
            previous_version: nil,
            previous_requirements: [{
              requirement: "^1.0.0",
              groups: ["dependencies"],
              source: nil,
              file: "pubspec.yaml"
            }]
          )
        ]
      end

      let(:dependency_files) do
        [
          Dependabot::DependencyFile.new(
            name: "pubspec.yaml",
            content: fixture("pubspec", "outdated_pubspec.yaml")
          )
        ]
      end

      it "should update the dependency" do
        expected_files = [
          Dependabot::DependencyFile.new(
            name: "pubspec.yaml",
            content: fixture("pubspec", "updated_pubspec.yaml")
          )
        ]
        expect(updated_files).to eq(expected_files)
      end
    end

    context "with a range dependency" do
      let(:dependencies) do
        [
          Dependabot::Dependency.new(
            name: "b",
            version: nil,
            package_manager: "pub",
            requirements: [{
              requirement: ">= 2.0.0 < 3.0.0",
              groups: ["dependencies"],
              source: nil,
              file: "pubspec.yaml"
            }],
            previous_version: nil,
            previous_requirements: [{
              requirement: ">= 1.0.0 < 2.0.0",
              groups: ["dependencies"],
              source: nil,
              file: "pubspec.yaml"
            }]
          )
        ]
      end

      let(:dependency_files) do
        [
          Dependabot::DependencyFile.new(
            name: "pubspec.yaml",
            content: fixture("pubspec", "outdated_range_pubspec.yaml")
          )
        ]
      end

      it "should update the dependency" do
        expected_files = [
          Dependabot::DependencyFile.new(
            name: "pubspec.yaml",
            content: fixture("pubspec", "updated_range_pubspec.yaml")
          )
        ]
        expect(updated_files).to eq(expected_files)
      end
    end
  end

  context "without a dependency file" do
    let(:dependency_files) { [] }
    let(:dependencies) { [] }

    it "should throw an error" do
      expect { file_updater_instance }.to raise_error(
        "No pubspec.yaml file"
      )
    end
  end
end
