# frozen_string_literal: true

require "rails_helper"

describe DiscourseBoosts::Boost do
  fab!(:post)
  fab!(:user)

  before { SiteSetting.discourse_boosts_enabled = true }

  describe "validations" do
    it "requires raw" do
      boost = DiscourseBoosts::Boost.new(post: post, user: user, raw: "", cooked: "")
      expect(boost).not_to be_valid
    end

    it "does not allow duplicate boosts for the same post and user" do
      Fabricate(:boost, post: post, user: user)

      duplicate = DiscourseBoosts::Boost.new(post: post, user: user, raw: "🎉")

      duplicate.valid?

      expect(duplicate.errors[:post_id]).to include(I18n.t("errors.messages.taken"))
    end

    it "enforces max visible length of 16" do
      boost = DiscourseBoosts::Boost.new(post: post, user: user, raw: "a" * 17)
      expect(boost).not_to be_valid
    end

    it "counts emoji as 1 visible character" do
      boost =
        DiscourseBoosts::Boost.new(
          post: post,
          user: user,
          raw: ":smiling_face_with_heart_eyes:" * 5,
        )
      expect(boost).to be_valid
    end

    it "does not count invalid emoji codes as 1 character" do
      boost =
        DiscourseBoosts::Boost.new(post: post, user: user, raw: ":not_a_real_emoji_code_at_all:")
      expect(boost).not_to be_valid
    end

    it "allows up to 5 emoji" do
      boost = DiscourseBoosts::Boost.new(post: post, user: user, raw: ":blush:" * 5)
      expect(boost).to be_valid
    end

    it "rejects more than 5 emoji" do
      boost = DiscourseBoosts::Boost.new(post: post, user: user, raw: ":blush:" * 6)
      expect(boost).not_to be_valid
    end

    it "counts native Unicode emoji toward the emoji limit" do
      boost = DiscourseBoosts::Boost.new(post: post, user: user, raw: "😀😃😄😁😆😅")
      expect(boost).not_to be_valid
    end

    it "allows up to 5 native Unicode emoji" do
      boost = DiscourseBoosts::Boost.new(post: post, user: user, raw: "😀😃😄😁😆")
      expect(boost).to be_valid
    end

    it "counts mixed shortcode and Unicode emoji together" do
      boost = DiscourseBoosts::Boost.new(post: post, user: user, raw: ":blush::blush::blush:😀😃😄")
      expect(boost).not_to be_valid
    end

    it "counts native Unicode emoji as 1 visible character each" do
      boost = DiscourseBoosts::Boost.new(post: post, user: user, raw: "👨‍👩‍👧‍👦" * 5)
      expect(boost).to be_valid
    end

    it "allows valid boost" do
      boost = DiscourseBoosts::Boost.new(post: post, user: user, raw: "🎉")
      expect(boost).to be_valid
    end
  end

  describe ".cook" do
    it "cooks emoji" do
      cooked = DiscourseBoosts::Boost.cook(":tada:")
      expect(cooked).to include("emoji")
    end

    it "does not render links" do
      cooked = DiscourseBoosts::Boost.cook("https://example.com")
      expect(cooked).not_to include("<a")
    end
  end

  describe "auto-cooking" do
    it "cooks raw on save" do
      boost = DiscourseBoosts::Boost.create!(post: post, user: user, raw: ":tada:")
      expect(boost.cooked).to include("emoji")
    end
  end
end
