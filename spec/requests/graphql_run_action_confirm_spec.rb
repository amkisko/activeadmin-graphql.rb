# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL confirm, dry_run, and run_action_field", type: :request do
  def gql!(query)
    post "/admin/graphql", params: {query: query}, as: :json
    JSON.parse(response.body)
  end

  context "when using SchemaField keywords with define_method" do
    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      previous = ns.graphql_configure_schema
      ns.graphql_configure_schema = lambda { |schema|
        schema.mutation.field :demo_run_action, ActiveAdmin::GraphQL::RunActionPayload,
          null: false,
          camelize: false,
          authorize: false,
          dry_run: true,
          confirm: true

        schema.mutation.define_method(:demo_run_action) do |confirm:, dry_run:|
          body = dry_run ? "preview" : "done"
          ActiveAdmin::GraphQL::RunActionPayload::Result.new(
            ok: true, status: 200, location: nil, body: body
          )
        end
      }
      with_resources_during(example) do
        ns.graphql = true
        ActiveAdmin.register(Post)
      end
    ensure
      ns.graphql_configure_schema = previous
      ActiveAdmin::GraphQL.clear_schema_cache!
    end

    it "returns confirm_required when confirm and dry_run are false" do
      data = gql!(<<~GQL)
        mutation {
          demo_run_action(confirm: false, dry_run: false) { ok body status }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "demo_run_action", "ok")).to be(false)
      expect(data.dig("data", "demo_run_action", "body")).to eq("confirm_required")
    end

    it "calls resolve when dry_run is true without a preview proc" do
      data = gql!(<<~GQL)
        mutation {
          demo_run_action(dry_run: true) { ok body }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "demo_run_action", "body")).to eq("preview")
    end

    it "calls resolve when confirm is true" do
      data = gql!(<<~GQL)
        mutation {
          demo_run_action(confirm: true) { ok body }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "demo_run_action", "body")).to eq("done")
    end
  end

  context "when using RunActionField.define with preview" do
    let(:resolve_calls) { [0] }

    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      previous = ns.graphql_configure_schema
      calls = resolve_calls
      ns.graphql_configure_schema = lambda { |schema|
        ActiveAdmin::GraphQL::RunActionField.define(
          schema.mutation,
          :create_batch,
          authorize: false,
          dry_run: true,
          confirm: true
        ) do
          argument :q, ::GraphQL::Types::String, required: true, camelize: false

          preview do |q:, **|
            (q == "ok") ? ok("would_run:create_batch") : refuse("not_ready")
          end

          resolve do |q:, **|
            calls[0] += 1
            ActiveAdmin::GraphQL::RunActionPayload::Result.new(
              ok: true, status: 200, location: nil, body: "ran:#{q}"
            )
          end
        end
      }
      with_resources_during(example) do
        ns.graphql = true
        ActiveAdmin.register(Post)
      end
    ensure
      ns.graphql_configure_schema = previous
      ActiveAdmin::GraphQL.clear_schema_cache!
    end

    it "returns preview without calling resolve when dry_run is true" do
      data = gql!(<<~GQL)
        mutation {
          create_batch(q: "ok", dry_run: true) { ok body }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "create_batch", "body")).to eq("would_run:create_batch")
      expect(resolve_calls[0]).to eq(0)
    end

    it "returns refused preview without calling resolve" do
      data = gql!(<<~GQL)
        mutation {
          create_batch(q: "no", confirm: true) { ok body }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "create_batch", "ok")).to be(false)
      expect(data.dig("data", "create_batch", "body")).to eq("not_ready")
      expect(resolve_calls[0]).to eq(0)
    end

    it "calls resolve when preview allows and confirm is true" do
      data = gql!(<<~GQL)
        mutation {
          create_batch(q: "ok", confirm: true) { ok body }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "create_batch", "body")).to eq("ran:ok")
      expect(resolve_calls[0]).to eq(1)
    end
  end
end
