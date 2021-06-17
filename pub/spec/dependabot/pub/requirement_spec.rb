# frozen_string_literal: true

require "spec_helper"
require "dependabot/pub/requirement"

RSpec.describe Dependabot::Pub::Requirement do
  describe "requirements_array" do
    it "should return a Dependabot::Pub::Requirement array with one instance" do
      requirements = described_class.requirements_array(">= 1.0.0 < 2.0.0")
      expect(requirements.size).to eq(1)
      expect(requirements[0]).to be_a(Dependabot::Pub::Requirement)
      expect(requirements[0].requirements).to match_array(
        [
          [">=", Dependabot::Pub::Version.new("1.0.0")],
          ["<", Dependabot::Pub::Version.new("2.0.0")]
        ]
      )
    end
  end

  describe "build requirement" do
    context "for valid requirements" do
      [
        [
          ["1.0.0"],
          [["=", "1.0.0"]]
        ],
        [
          [">= 1.0.0"],
          [[">=", "1.0.0"]]
        ],
        [
          ["> 1.0.0"],
          [[">", "1.0.0"]]
        ],
        [
          ["<= 1.0.0"],
          [["<=", "1.0.0"]]
        ],
        [
          ["< 1.0.0"],
          [["<", "1.0.0"]]
        ],
        [
          ["any"],
          [["any", "0.0.0"]]
        ],
        [
          ["^1.0.0"],
          [["^", "1.0.0"]]
        ],
        [
          [">= 1.0.0 < 2.0.0"],
          [[">=", "1.0.0"], ["<", "2.0.0"]]
        ],
        [
          ["<= 1.1.2 > 1.1.0"],
          [["<=", "1.1.2"], [">", "1.1.0"]]
        ],
        [
          [">= 1.0.0", "< 2.0.0"],
          [[">=", "1.0.0"], ["<", "2.0.0"]]
        ],
        [
          ["<= 1.1.2", "> 1.1.0"],
          [["<=", "1.1.2"], [">", "1.1.0"]]
        ],
        [
          [">=0.1.0-a.0 <2.0.0"],
          [[">=", "0.1.0-a.0"], ["<", "2.0.0"]]
        ],
        [
          ["^1.0.0-a.0"],
          [["^", "1.0.0-a.0"]]
        ],
        [
          "1.0.0",
          [["=", "1.0.0"]]
        ],
        [
          [Dependabot::Pub::Version.new("1.0.0"), Gem::Version.new("2.0.0")],
          [["=", "1.0.0"], ["=", "2.0.0"]]
        ],
        [
          ["1.0.0", "1.0.0"],
          [["=", "1.0.0"]]
        ]
      ].each do |reqs, exp|
        it "#{reqs.inspect} which should parse as #{exp.inspect}" do
          requirement = described_class.new(reqs)
          mapped = requirement.requirements.map do |res|
            [res[0], res[1].to_s]
          end
          expect(mapped).to match_array(exp)
        end
      end
    end

    context "for bad requirements" do
      [
        ["version"],
        ["1.0.0", "version"],
        ["!=1.0.0"],
        ["^1.0.0 <1.2.0"]
      ].each do |reqs|
        it "#{reqs.inspect} which should raise BadRequirementError" do
          expect { described_class.new(reqs) }.
            to raise_error(Gem::Requirement::BadRequirementError)
        end
      end
    end

    context "for default requirement" do
      it "should return the default requirement" do
        expect(Dependabot::Pub::Requirement::DefaultRequirement).to eq([">=", Dependabot::Pub::Version.new("0.0.0")])
        expect(described_class.new(">= 0").requirements).to eq([Dependabot::Pub::Requirement::DefaultRequirement])
      end
    end
  end

  describe "check satisfied_by?" do
    values = [
      [
        ["1.0.0"],
        ["1.0.0"],
        ["0.1.0", "1.1.0", "2.0.0"]
      ],
      [
        [">= 1.0.0"],
        ["1.0.0", "1.1.0", "2.0.0"],
        ["0.1.0"]
      ],
      [
        ["> 1.0.0"],
        ["1.1.0", "2.0.0"],
        ["1.0.0", "0.1.0"]
      ],
      [
        ["<= 1.0.0"],
        ["1.0.0", "0.1.0"],
        ["1.1.0", "2.0.0"]
      ],
      [
        ["< 1.0.0"],
        ["0.1.0"],
        ["1.0.0", "1.1.0", "2.0.0"]
      ],
      [
        ["any"],
        ["0.1.0", "1.0.0", "1.1.0", "2.0.0"],
        []
      ],
      [
        ["^1.0.0"],
        ["1.0.0", "1.1.0"],
        ["0.1.0", "2.0.0"]
      ],
      [
        ["^0.1.0"],
        ["0.1.0", "0.1.1"],
        ["0.2.0", "1.0.0", "0.0.1"]
      ],
      [
        [">= 1.0.0 < 2.0.0"],
        ["1.0.0", "1.1.0"],
        ["0.1.0", "2.0.0"]
      ],
      [
        ["<= 1.1.2 > 1.1.0"],
        [],
        ["0.1.0", "1.0.0", "1.1.0", "2.0.0"]
      ]
    ]

    values.each do |requirements, valid, invalid|
      it "for valid versions #{valid.inspect} with requirements #{requirements}" do
        requirement = described_class.new(requirements)
        valid.each do |version|
          expect(requirement.satisfied_by?(version)).to eq(true)
        end
      end

      it "for invalid versions #{invalid.inspect} with requirements #{requirements}" do
        requirement = described_class.new(requirements)
        invalid.each do |version|
          expect(requirement.satisfied_by?(version)).to eq(false)
        end
      end
    end
  end
end
