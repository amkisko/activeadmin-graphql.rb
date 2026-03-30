# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe ActiveAdmin::GraphQL::ResourceQueryProxy do
  around do |example|
    with_resources_during(example) { ActiveAdmin.register(Post) }
  end

  let(:aa_res) { ActiveAdmin.application.namespaces[:admin].resource_for(Post) }
  let(:namespace) { ActiveAdmin.application.namespaces[:admin] }

  describe "#relation_for_index" do
    it "returns an ActiveRecord::Relation" do
      proxy = described_class.new(aa_resource: aa_res, user: nil, namespace: namespace, graph_params: {})
      expect(proxy.send(:relation_for_index)).to be_a(ActiveRecord::Relation)
    end

    it "applies Ransack q the same way as ResourceController" do
      Post.create!(title: "ProxySearch", body: "x")
      Post.create!(title: "Other", body: "y")

      proxy = described_class.new(
        aa_resource: aa_res,
        user: nil,
        namespace: namespace,
        graph_params: {"q" => {"title_cont" => "ProxySearch"}}
      )
      titles = proxy.send(:relation_for_index).pluck(:title)
      expect(titles).to eq(["ProxySearch"])
    end
  end

  describe "#find_member" do
    it "finds the record by id" do
      post = Post.create!(title: "Member", body: "z")
      proxy = described_class.new(aa_resource: aa_res, user: nil, namespace: namespace, graph_params: {})
      expect(proxy.find_member(post.id)).to eq(post)
    end

    context "with LibraryEdition (composite primary key)" do
      around do |example|
        with_resources_during(example) { ActiveAdmin.register(LibraryEdition) }
      end

      let(:aa_res) { ActiveAdmin.application.namespaces[:admin].resource_for(LibraryEdition) }

      it "finds by JSON id or by primary-key param hash" do
        ed = LibraryEdition.create!(book_code: "Q", seq: 4, label: "L")
        proxy = described_class.new(aa_resource: aa_res, user: nil, namespace: namespace, graph_params: {})
        expect(proxy.find_member(ActiveAdmin::PrimaryKey.graphql_id_value(ed))).to eq(ed)
        expect(proxy.find_member("book_code" => "Q", "seq" => 4)).to eq(ed)
      end
    end
  end

  describe "#build_new" do
    it "builds an unsaved record with permitted attributes" do
      proxy = described_class.new(aa_resource: aa_res, user: nil, namespace: namespace, graph_params: {})
      record = proxy.build_new("title" => "Built", "body" => "b")
      expect(record).to be_new_record
      expect(record.title).to eq("Built")
    end
  end

  describe "#run_batch_action, #run_member_action, #run_collection_action" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.register(Post) do
          batch_action :unit_star, confirm: false do |ids|
            batch_action_collection.find(ids).each { |p| p.update!(starred: true) }
            redirect_to collection_path
          end

          member_action :unit_suffix, method: :put do
            resource.update!(title: "#{resource.title} suffix")
            redirect_to resource_path(resource)
          end

          collection_action :unit_totals, method: :get do
            render json: {n: collection.count}
          end
        end
      end
    end

    let(:aa_res) { ActiveAdmin.application.namespaces[:admin].resource_for(Post) }

    it "runs a batch action with the same controller context as the UI" do
      a = Post.create!(title: "U1", body: "a", starred: false)
      proxy = described_class.new(aa_resource: aa_res, user: nil, namespace: namespace, graph_params: {})
      result = proxy.run_batch_action("unit_star", [a.id])
      expect(result.ok).to be(true)
      expect(a.reload.starred).to be(true)
    end

    it "runs a member action" do
      post = Post.create!(title: "U2", body: "b")
      proxy = described_class.new(aa_resource: aa_res, user: nil, namespace: namespace, graph_params: {})
      result = proxy.run_member_action("unit_suffix", post.id)
      expect(result.ok).to be(true)
      expect(post.reload.title).to eq("U2 suffix")
    end

    it "runs a collection action" do
      Post.create!(title: "U3", body: "c")
      Post.create!(title: "U4", body: "d")
      proxy = described_class.new(aa_resource: aa_res, user: nil, namespace: namespace, graph_params: {})
      result = proxy.run_collection_action("unit_totals")
      expect(result.ok).to be(true)
      expect(result.body).to be_present
      expect(JSON.parse(result.body)["n"]).to eq(2)
    end
  end
end
