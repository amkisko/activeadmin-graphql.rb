# frozen_string_literal: true

# Fixture model on view alert_events (no PK, no id column; virtual composite id).
class AlertEvent < ApplicationRecord
  self.primary_key = nil

  def id
    [entry_type, entry_id, event_type].join(":")
  end
end
