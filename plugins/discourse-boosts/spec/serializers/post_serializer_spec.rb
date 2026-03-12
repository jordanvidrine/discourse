# frozen_string_literal: true

RSpec.describe PostSerializer do
  fab!(:user)
  fab!(:post_author, :user)
  fab!(:category)
  fab!(:topic) { Fabricate(:topic, category: category) }
  fab!(:target_post, :post) { Fabricate(:post, topic: topic, user: post_author) }

  let(:guardian) { Guardian.new(user) }
  let(:topic_view) { TopicView.new(topic, user) }

  let(:serialized) do
    post = topic_view.posts.find { |p| p.id == target_post.id }
    serializer = described_class.new(post, scope: guardian, root: false)
    serializer.topic_view = topic_view
    serializer.as_json
  end

  before { SiteSetting.discourse_boosts_enabled = true }

  describe "can_boost" do
    it "is true for a regular user on another user's post" do
      expect(serialized[:can_boost]).to eq(true)
    end

    context "when user is silenced" do
      before { user.update!(silenced_till: 1.year.from_now) }

      it "is false" do
        expect(serialized[:can_boost]).to eq(false)
      end
    end
  end
end
