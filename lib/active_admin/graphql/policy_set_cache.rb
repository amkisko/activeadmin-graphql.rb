# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Request-scoped memoization for ActiveAdmin policy sets on GraphQL objects.
    class PolicySetCache
      class << self
        def fetch(context, subject_owner:, subject:)
          namespace = context[:namespace]
          unless namespace
            return policy_builder(context).send(
              :build_policy_set,
              auth: context[:auth],
              subject_owner: subject_owner,
              subject: subject,
              context: context
            )
          end

          cache = context[:policy_set_cache] ||= {}
          key = cache_key(subject_owner, subject)
          cache[key] ||= policy_builder(context).send(
            :build_policy_set,
            auth: context[:auth],
            subject_owner: subject_owner,
            subject: subject,
            context: context
          )
        end

        def policy_builder(context)
          context[:policy_schema_builder] ||= SchemaBuilder.new(context[:namespace])
        end

        def cache_key(subject_owner, subject)
          owner_key = subject_owner_key(subject_owner)
          "#{owner_key}:#{subject_key(subject)}"
        end

        private

        def subject_owner_key(subject_owner)
          if subject_owner.is_a?(ActiveAdmin::Page)
            "page-owner:#{subject_owner.name}"
          else
            "resource-owner:#{subject_owner.resource_class.name}"
          end
        end

        def subject_key(subject)
          if subject.is_a?(Class)
            "class:#{subject.name}"
          elsif subject.is_a?(ActiveAdmin::Page)
            "page:#{subject.name}"
          elsif subject.is_a?(ActiveRecord::Base)
            "record:#{subject.class.name}:#{PrimaryKey.graphql_id_value(subject)}"
          else
            "object:#{subject.object_id}"
          end
        end
      end
    end
  end
end
