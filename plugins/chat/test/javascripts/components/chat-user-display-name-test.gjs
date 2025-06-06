import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ChatUserDisplayName from "discourse/plugins/chat/discourse/components/chat-user-display-name";

module(
  "Discourse Chat | Component | chat-user-display-name | prioritize username in UX",
  function (hooks) {
    setupRenderingTest(hooks);

    test("username and no name", async function (assert) {
      const self = this;

      this.siteSettings.prioritize_username_in_ux = true;
      this.set("user", { username: "bob", name: null });

      await render(
        <template><ChatUserDisplayName @user={{self.user}} /></template>
      );

      assert.dom(".chat-user-display-name").hasText("bob");
    });

    test("username and name", async function (assert) {
      const self = this;

      this.siteSettings.prioritize_username_in_ux = true;
      this.set("user", { username: "bob", name: "Bobcat" });

      await render(
        <template><ChatUserDisplayName @user={{self.user}} /></template>
      );

      assert.dom(".chat-user-display-name").hasText("bob Bobcat");
    });
  }
);

module(
  "Discourse Chat | Component | chat-user-display-name | prioritize name in UX",
  function (hooks) {
    setupRenderingTest(hooks);

    test("no name", async function (assert) {
      const self = this;

      this.siteSettings.prioritize_username_in_ux = false;
      this.set("user", { username: "bob", name: null });

      await render(
        <template><ChatUserDisplayName @user={{self.user}} /></template>
      );

      assert.dom(".chat-user-display-name").hasText("bob");
    });

    test("name and username", async function (assert) {
      const self = this;

      this.siteSettings.prioritize_username_in_ux = false;
      this.set("user", { username: "bob", name: "Bobcat" });

      await render(
        <template><ChatUserDisplayName @user={{self.user}} /></template>
      );

      assert.dom(".chat-user-display-name").hasText("Bobcat bob");
    });
  }
);
