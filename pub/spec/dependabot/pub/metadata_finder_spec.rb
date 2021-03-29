# frozen_string_literal: true

require "spec_helper"
require "dependabot/pub/metadata_finder"
require_common_spec "metadata_finders/shared_examples_for_metadata_finders"

RSpec.describe Dependabot::Pub::MetadataFinder do
  it_behaves_like "a dependency metadata finder"

  let(:credentials) do
    [{
      "type" => "git_source",
      "host" => "github.com",
      "username" => "x-access-token",
      "password" => "token"
    }]
  end
  let(:metadata_finder_instance) do
    described_class.new(
      dependency: dependency,
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

    subject(:source_url) { metadata_finder_instance.source_url }

    context "when the response status is 200" do
      before do
        stub_request(:get, "https://pub.dartlang.org/api/packages/a").
          to_return(
            status: 200,
            body: fixture("pub", "#{fixture_name}.json"),
            headers: json_header
          )
      end

      context "with homepage" do
        let(:fixture_name) { "package_homepage" }

        it "returns the url" do
          expect(source_url).to eq("https://github.com/dependabot/dependabot-core")
        end
      end

      context "with repository" do
        let(:fixture_name) { "package_repository" }

        it "returns the url" do
          expect(source_url).to eq("https://github.com/dependabot/dependabot-script")
        end
      end

      context "with both" do
        let(:fixture_name) { "package_both" }

        it "returns the url" do
          expect(source_url).to eq("https://github.com/dependabot/dependabot-script")
        end
      end

      context "with none" do
        let(:fixture_name) { "package_none" }

        it "returns the url" do
          expect(source_url).to eq(nil)
        end
      end
    end

    context "when the response status is 400" do
      before do
        stub_request(:get, "https://pub.dartlang.org/api/packages/a").
          to_return(
            status: 400,
            body: "",
            headers: json_header
          )
      end

      it "raise an error" do
        expect { subject }.to raise_error(
          "Unable to get package info"
        )
      end
    end
  end
end
