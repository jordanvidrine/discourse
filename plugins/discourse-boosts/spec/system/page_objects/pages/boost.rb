# frozen_string_literal: true

module PageObjects
  module Pages
    class Boost < PageObjects::Pages::Base
      def click_boost_button(post)
        find("#post_#{post.post_number} .post-action-menu__boost").click
        self
      end

      def fill_in_boost(text)
        editor = find(".discourse-boosts__input-container .ProseMirror")
        editor.send_keys(text)
        self
      end

      def submit_boost
        find(".discourse-boosts__submit").click
        self
      end

      def has_boost?(post, cooked_content = nil)
        selector = "#post_#{post.post_number} .discourse-boosts .discourse-boosts__cooked"
        if cooked_content
          has_css?("#{selector} img.emoji[alt='#{cooked_content}']")
        else
          has_css?(selector)
        end
      end

      def has_no_boosts?(post)
        has_no_css?("#post_#{post.post_number} .discourse-boosts")
      end

      def has_boost_button?(post)
        has_css?("#post_#{post.post_number} .post-action-menu__boost")
      end

      def has_no_boost_button?(post)
        has_no_css?("#post_#{post.post_number} .post-action-menu__boost")
      end
    end
  end
end
