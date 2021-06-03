# frozen_string_literal: true

require "spec_helper"
require "dependabot/pub/file_fetcher"
require_common_spec "file_fetchers/shared_examples_for_file_fetchers"

RSpec.describe Dependabot::Pub::FileFetcher do
  it_behaves_like "a dependency file fetcher"

  let(:source) do
    Dependabot::Source.new(
      provider: "github",
      repo: "JohannSchramm/dependabot-pub-example",
      directory: "/"
    )
  end
  let(:credentials) do
    [{
      "type" => "git_source",
      "host" => "github.com",
      "username" => "x-access-token",
      "password" => "token"
    }]
  end
  let(:file_fetcher_instance) do
    described_class.new(source: source, credentials: credentials)
  end

  let(:url) { "https://api.github.com/repos/JohannSchramm/dependabot-pub-example/contents/" }

  let(:json_header) { { "content-type" => "application/json" } }
  before { allow(file_fetcher_instance).to receive(:commit).and_return("sha") }

  context "with a pubspec.yaml file and without a pubspec.lock file" do
    before do
      stub_request(:get, url + "?ref=sha").
        with(headers: { "Authorization" => "token token" }).
        to_return(
          status: 200,
          body: fixture("github", "contents_repo_pubspec.json"),
          headers: json_header
        )
      stub_request(:get, url + "pubspec.yaml?ref=sha").
        with(headers: { "Authorization" => "token token" }).
        to_return(
          status: 200,
          body: fixture("github", "contents_pubspec.json"),
          headers: json_header
        )
    end

    it "fetches the pubspec.yaml file" do
      expect(file_fetcher_instance.files.map(&:name)).to match_array(
        %w(pubspec.yaml)
      )
    end
  end

  context "with both a pubspec.yaml and a pubspec.lock file" do
    before do
      stub_request(:get, url + "?ref=sha").
        with(headers: { "Authorization" => "token token" }).
        to_return(
          status: 200,
          body: fixture("github", "contents_repo_both.json"),
          headers: json_header
        )
      stub_request(:get, url + "pubspec.yaml?ref=sha").
        with(headers: { "Authorization" => "token token" }).
        to_return(
          status: 200,
          body: fixture("github", "contents_pubspec.json"),
          headers: json_header
        )
      stub_request(:get, url + "pubspec.lock?ref=sha").
        with(headers: { "Authorization" => "token token" }).
        to_return(
          status: 200,
          body: fixture("github", "contents_lock.json"),
          headers: json_header
        )
    end

    it "fetches the pubspec.yaml and pubspec.lock file" do
      expect(file_fetcher_instance.files.map(&:name)).to match_array(
        %w(pubspec.yaml pubspec.lock)
      )
    end
  end

  context "without a pubspec.yaml or pubspec.lock file" do
    before do
      stub_request(:get, url + "?ref=sha").
        with(headers: { "Authorization" => "token token" }).
        to_return(
          status: 200,
          body: fixture("github", "contents_repo_none.json"),
          headers: json_header
        )
    end

    it "raises a helpful error" do
      expect { file_fetcher_instance.files }.to raise_error(
        Dependabot::DependencyFileNotFound
      )
    end
  end

  context "without a pubspec.yaml file but with a pubspec.lock file" do
    before do
      stub_request(:get, url + "?ref=sha").
        with(headers: { "Authorization" => "token token" }).
        to_return(
          status: 200,
          body: fixture("github", "contents_repo_lock.json"),
          headers: json_header
        )
    end

    it "raises a helpful error" do
      expect { file_fetcher_instance.files }.to raise_error(
        Dependabot::DependencyFileNotFound
      )
    end
  end
end
