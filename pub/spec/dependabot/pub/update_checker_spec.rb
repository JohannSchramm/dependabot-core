# frozen_string_literal: true

require "spec_helper"
require "dependabot/pub/update_checker"
require_common_spec "update_checkers/shared_examples_for_update_checkers"

RSpec.describe Dependabot::Pub::UpdateChecker do
  it_behaves_like "an update checker"

  let(:credentials) do
    [{
      "type" => "git_source",
      "host" => "github.com",
      "username" => "x-access-token",
      "password" => "token"
    }]
  end
  let(:update_checker_instance) do
    described_class.new(
      dependency: dependency,
      dependency_files: [],
      credentials: credentials
    )
  end

  let(:json_header) { { "content-type" => "application/json" } }

  context "for a dependency" do
    let(:dependency) do
      Dependabot::Dependency.new(
        name: "a",
        version: nil,
        package_manager: "pub",
        requirements: [{
          requirement: "^1.0.0",
          groups: ["dependencies"],
          source: nil,
          file: "pubspec.yaml"
        }]
      )
    end

    before do
      stub_request(:get, "https://pub.dartlang.org/packages/a.json").
        to_return(
          status: 200,
          body: fixture("pub", "versions.json"),
          headers: json_header
        )
    end

    it "return the latest version" do
      expect(update_checker_instance.latest_version).to eq(Dependabot::Pub::Version.new("2.1.0"))
    end

    it "return the latest resolvable version" do
      expect(update_checker_instance.latest_resolvable_version).to eq(Dependabot::Pub::Version.new("1.1.0"))
    end

    it "return updated requirements" do
      expect(update_checker_instance.updated_requirements).to eq(
        [{
          requirement: "^2.1.0",
          groups: ["dependencies"],
          source: nil,
          file: "pubspec.yaml"
        }]
      )
    end

    context "with build number" do
      let(:dependency) do
        Dependabot::Dependency.new(
          name: "a",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: "^0.1.0+1",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        )
      end

      before do
        stub_request(:get, "https://pub.dartlang.org/packages/a.json").
          to_return(
            status: 200,
            body: fixture("pub", "versions_build.json"),
            headers: json_header
          )
      end

      it "return the latest version" do
        expect(update_checker_instance.latest_version).to eq(Dependabot::Pub::Version.new("1.0.0"))
      end

      it "return the latest resolvable version" do
        expect(update_checker_instance.latest_resolvable_version).to eq(Dependabot::Pub::Version.new("0.1.0+2"))
      end

      it "return updated requirements" do
        expect(update_checker_instance.updated_requirements).to eq(
          [{
            requirement: "^1.0.0",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        )
      end
    end

    context "with range requirement" do
      let(:dependency) do
        Dependabot::Dependency.new(
          name: "a",
          version: nil,
          package_manager: "pub",
          requirements: [{
            requirement: ">=0.1.0 <0.1.3",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        )
      end

      before do
        stub_request(:get, "https://pub.dartlang.org/packages/a.json").
          to_return(
            status: 200,
            body: fixture("pub", "versions_build.json"),
            headers: json_header
          )
      end

      it "return the latest version" do
        expect(update_checker_instance.latest_version).to eq(Dependabot::Pub::Version.new("1.0.0"))
      end

      it "return the latest resolvable version" do
        expect(update_checker_instance.latest_resolvable_version).to eq(Dependabot::Pub::Version.new("0.1.0+2"))
      end

      it "return updated requirements" do
        expect(update_checker_instance.updated_requirements).to eq(
          [{
            requirement: "^1.0.0",
            groups: ["dependencies"],
            source: nil,
            file: "pubspec.yaml"
          }]
        )
      end
    end
  end
end
