# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # Enforces per-file line count. RuboCop core does not ship Metrics/FileLength.
      # WarnMax is the preferred size. Max is the alert limit.
      # Blank lines and comments count, matching reviewable file size rather than folded class length.
      class FileLength < Base
        MSG_WARNING = "File is over the preferred line count. [%<length>d/%<warn_max>d]"
        MSG_ALERT = "File has too many lines. [%<length>d/%<max>d]"

        def on_new_investigation
          super

          current = processed_source.lines.count
          warn_max = configured_limit("WarnMax")
          max = configured_limit("Max")

          if max && current > max
            add_global_offense(format(MSG_ALERT, length: current, max: max), severity: :error)
          elsif warn_max && current > warn_max
            add_global_offense(
              format(MSG_WARNING, length: current, warn_max: warn_max),
              severity: :info
            )
          end
        end

        private

        def configured_limit(key)
          value = cop_config[key]
          Integer(value) unless value.nil?
        end
      end
    end
  end
end
