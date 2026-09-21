# frozen_string_literal: true

require "rubocop"
require_relative "../../rubocop/cop/metrics/file_length"

RSpec.describe RuboCop::Cop::Metrics::FileLength do
  def offenses_for(line_count, warn_max: 150, max: 300)
    lines = Array.new(line_count) { "x = 1" }
    source = lines.join("\n")
    config = RuboCop::Config.new(
      {
        "AllCops" => {"TargetRubyVersion" => 3.2},
        "Metrics/FileLength" => {
          "Enabled" => true,
          "WarnMax" => warn_max,
          "Max" => max
        }
      },
      File.expand_path("../../.rubocop.yml", __dir__)
    )
    processed = RuboCop::ProcessedSource.new(source, 3.2, "example.rb")
    expect(processed.lines.count).to eq(line_count)
    team = RuboCop::Cop::Team.mobilize([described_class], config, raise_error: true)
    team.investigate(processed).offenses
  end

  it "does not report at the preferred file size" do
    expect(offenses_for(150)).to be_empty
  end

  it "reports info above the preferred file size" do
    offenses = offenses_for(151)
    expect(offenses.size).to eq(1)
    expect(offenses.first.severity.name).to eq(:info)
    expect(offenses.first.message).to include("[151/150]")
  end

  it "keeps info at the alert limit" do
    offenses = offenses_for(300)
    expect(offenses.size).to eq(1)
    expect(offenses.first.severity.name).to eq(:info)
    expect(offenses.first.message).to include("[300/150]")
  end

  it "reports an error above the alert limit" do
    offenses = offenses_for(301)
    expect(offenses.size).to eq(1)
    expect(offenses.first.severity.name).to eq(:error)
    expect(offenses.first.message).to include("[301/300]")
  end
end
