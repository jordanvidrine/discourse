# frozen_string_literal: true

module PageObjects
  module Pages
    class Login < PageObjects::Pages::Base
      def open?
        has_css?(".login-fullpage")
      end

      def closed?
        has_no_css?(".login-fullpage")
      end

      def open
        visit("/login")
        self
      end

      def open_with_redirect(redirect_path)
        visit("/login?redirect=#{redirect_path}")
        self
      end

      def open_from_header
        find(".login-button").click
      end

      def click(selector)
        if page.has_css?("html.mobile-view", wait: 0)
          expect(page).to have_no_css(".d-modal.is-animating")
        end
        find(selector).click
      end

      def open_signup
        click("#new-account-link")
      end

      def click_login
        click("#login-button")
      end

      def email_login_link
        click("#email-login-link")
      end

      def forgot_password
        click("#forgot-password-link")
      end

      def fill_input(selector, text)
        if page.has_css?("html.mobile-view", wait: 0)
          expect(page).to have_no_css(".d-modal.is-animating")
        end
        find(selector).fill_in(with: text)
      end

      def fill_username(username)
        fill_input("#login-account-name", username)
        self
      end

      def fill_password(password)
        fill_input("#login-account-password", password)
        self
      end

      def fill(username: nil, password: nil)
        fill_username(username) if username
        fill_password(password) if password
        self
      end

      def click_social_button(provider)
        click(".btn-social.#{provider}")
      end
    end
  end
end
