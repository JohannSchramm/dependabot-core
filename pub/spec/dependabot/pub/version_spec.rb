# frozen_string_literal: true

require "spec_helper"
require "dependabot/pub/version"

RSpec.describe Dependabot::Pub::Version do
  describe "check version string validity" do
    context "for a valid version" do
      values = [
        "1.0.0",
        "1.0.0-test",
        "1.0.0-test.1",
        "1.0.0+1",
        "1.0.0+1.0",
        "1.0.0-test+1",
        "1.0.0-test+test",
        "1.0.0-a-b+c-d",
        "1.0.0+a-b",
        "1.0.0-test.1+1.0"
      ]
      values.each do |version|
        it "that is #{version}" do
          valid = described_class.correct?(version)
          expect(valid).to eq(true)
        end
      end
    end

    context "for an invalid version" do
      values = [
        "1.0-test",
        "test",
        "test-test",
        "test+test",
        "1.0.0+test-test+test",
        "",
        nil
      ]
      values.each do |version|
        it "that is #{version}" do
          valid = described_class.correct?(version)
          expect(valid).to eq(false)
        end
      end
    end

    it "parses the correct pre release and build number" do
      version = described_class.new("1.0.0+a-b")
      expect(version.prerelease_string).to eq(nil)
      expect(version.build_number_string).to eq("a-b")
    end

    it "parses the correct version number, prerelease and build number" do
      version = described_class.new("1.2.3-a+b")
      expect(version.version_number_string).to eq("1.2.3")
      expect(version.prerelease_string).to eq("a")
      expect(version.build_number_string).to eq("b")
    end

    it "raises an error for an invalid version" do
      expect { described_class.new("1.0.0+test-test+test") }.
        to raise_error(ArgumentError)
    end
  end

  describe "check comparison" do
    context "with another Dependabot::Pub::Version" do
      context "when sorting an array" do
        list = [
          "0.9.0-a",
          "0.9.0-a.1",
          "0.9.0",
          "0.9.0+1",
          "1.0.0-b.1",
          "1.0.0-b.2",
          "1.0.0-c.1",
          "1.0.0-c.1+1",
          "1.0.0",
          "1.0.0+1",
          "1.1.0+1",
          "1.1.0+1.0.0",
          "1.3.7+1.1.0",
          "2.0.0",
          "2.1.0",
          "2.1.1",
          "2.2.0",
          "2.3.0"
        ]
        it "is equal" do
          versions = list.map { |v| described_class.new(v) }
          expect(versions.reverse.sort).to eq(versions)
        end
      end

      context "which is equal" do
        values = [
          ["1.0.0", "1.0.0"],
          ["1.0.0-test", "1.0.0-test"],
          ["1.0.0-test.1", "1.0.0-test.1"],
          ["1.0.0+1", "1.0.0+1"],
          ["1.0.0+test.1", "1.0.0+test.1"],
          ["1.0.0-test+1", "1.0.0-test+1"]
        ]
        values.each do |a, b|
          it "for #{a} and #{b}" do
            version_a = described_class.new(a)
            version_b = described_class.new(b)
            expect(version_a <=> version_b).to eq(0)
          end
        end
      end

      context "which is lower" do
        values = [
          ["1.0.0", "0.9.0"],
          ["1.0.0", "1.0.0-test"],
          ["1.0.0-test", "0.9.0-test"],
          ["1.0.0-test.1", "1.0.0-test.0"],
          ["1.0.0-test.1", "1.0.0-test"],
          ["1.0.0-test.1", "1.0.0-0.1"],
          ["1.0.0", "0.9.0+1"],
          ["1.0.0+1", "0.9.0+1"],
          ["1.0.0+test.1", "1.0.0+test.0"],
          ["1.0.0-test+1", "1.0.0-a+0"],
          ["1.0.0-test+1", "1.0.0-a+1"],
          ["1.0.0-test+1", "1.0.0-test+0"]
        ]
        values.each do |a, b|
          it "for #{a} and #{b}" do
            version_a = described_class.new(a)
            version_b = described_class.new(b)
            expect(version_a <=> version_b).to eq(1)
          end
        end
      end

      context "which is greater" do
        values = [
          ["1.0.0", "1.1.0"],
          ["1.0.0-test", "1.0.0"],
          ["1.0.0-test", "1.0.0-test2"],
          ["1.0.0-test.1", "1.0.0-test.2"],
          ["1.0.0-test.1", "1.0.0-test.1.1"],
          ["1.0.0-test.1", "1.0.0-z.1"],
          ["1.0.0", "1.0.0+1"],
          ["1.0.0+1", "1.0.0+2"],
          ["1.0.0+test.1", "1.0.0+test.2"],
          ["1.0.0+test.1", "1.0.0+test.2"],
          ["1.0.0-test+1", "1.0.0-z+2"],
          ["1.0.0-test+1", "1.0.0-z+1"],
          ["1.0.0-test+1", "1.0.0-test+2"],
          ["1.0.0-test+1", "1.0.0-test+test"]
        ]
        values.each do |a, b|
          it "for #{a} and #{b}" do
            version_a = described_class.new(a)
            version_b = described_class.new(b)
            expect(version_a <=> version_b).to eq(-1)
          end
        end
      end
    end

    context "with another Gem::Version" do
      subject { version <=> other }

      let(:version) { described_class.new("1.0.0+1") }
      context "that is equal" do
        let(:other) { Gem::Version.new("1.0.0") }
        it { is_expected.to eq(0) }
      end

      context "that is lower" do
        let(:other) { Gem::Version.new("0.9.0") }
        it { is_expected.to eq(1) }
      end

      context "that is greater" do
        let(:other) { Gem::Version.new("1.1.0") }
        it { is_expected.to eq(-1) }
      end
    end
  end

  describe "check priority" do
    context "when sorting an array" do
      list = [
        "0.9.0-a",
        "0.9.0-a.1",
        "1.0.0-b.1",
        "1.0.0-b.2",
        "1.0.0-c.1",
        "1.0.0-c.1+1",
        "2.0.0-a",
        "3.0.0-a",
        "3.0.0-b",
        "0.9.0",
        "0.9.0+1",
        "1.0.0",
        "1.0.0+1",
        "1.1.0+1",
        "1.1.0+1.0.0",
        "1.3.7+1.1.0",
        "2.0.0",
        "2.1.0",
        "2.1.1",
        "2.2.0",
        "2.3.0"
      ]
      it "is equal" do
        versions = list.map { |v| described_class.new(v) }
        expect(versions.reverse.sort { |a, b| a.priority b }).to eq(versions)
      end
    end
  end

  describe "check version string" do
    it "returns the given version string" do
      string = "1.0.0-test+test-test"
      version = described_class.new(string)
      expect(version.version).to eq(string)
      expect(version.to_s).to eq(string)
    end
  end

  describe "next breaking version" do
    values = [
      ["1.0.0", "2.0.0"],
      ["1.0.0-test", "2.0.0"],
      ["0.1.0", "0.2.0"],
      ["2.0.0", "3.0.0"],
      ["0.0.0", "0.1.0"],
      ["1.1.1", "2.0.0"],
      ["0.1.1", "0.2.0"],
      ["0.0.1", "0.1.0"]
    ]
    values.each do |version, expected|
      it "for #{version} should be #{expected}" do
        breaking = described_class.new(version).breaking
        expect(breaking).to eq(described_class.new(expected))
      end
    end
  end
end
