import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DoNotDisturbModal from "discourse/components/modal/do-not-disturb";
import UserStatusModal from "discourse/components/modal/user-status";
import { ajax } from "discourse/lib/ajax";
import DoNotDisturb from "discourse/lib/do-not-disturb";
import { userPath } from "discourse/lib/url";

const _extraItems = [];

export function addUserMenuProfileTabItem(item) {
  _extraItems.push(item);
}

export function resetUserMenuProfileTabItems() {
  _extraItems.clear();
}

export default class UserMenuProfileTabContent extends Component {
  @service currentUser;
  @service siteSettings;
  @service userStatus;
  @service modal;

  saving = false;

  get showToggleAnonymousButton() {
    return (
      this.currentUser.can_post_anonymously || this.currentUser.is_anonymous
    );
  }

  get isInDoNotDisturb() {
    return !!this.#doNotDisturbUntilDate;
  }

  get doNotDisturbDateTime() {
    return this.#doNotDisturbUntilDate.getTime();
  }

  get showDoNotDisturbEndDate() {
    return !DoNotDisturb.isEternal(
      this.currentUser.get("do_not_disturb_until")
    );
  }

  get extraItems() {
    return _extraItems;
  }

  get #doNotDisturbUntilDate() {
    if (!this.currentUser.get("do_not_disturb_until")) {
      return;
    }
    const date = new Date(this.currentUser.get("do_not_disturb_until"));
    if (date < new Date()) {
      return;
    }
    return date;
  }

  get isPresenceHidden() {
    return this.currentUser.get("user_option.hide_presence");
  }

  @action
  doNotDisturbClick() {
    if (this.saving) {
      return;
    }
    this.saving = true;
    if (this.currentUser.do_not_disturb_until) {
      return this.currentUser.leaveDoNotDisturb().finally(() => {
        this.saving = false;
      });
    } else {
      this.saving = false;
      this.args.closeUserMenu();
      this.modal.show(DoNotDisturbModal);
    }
  }

  @action
  togglePresence() {
    this.currentUser.set("user_option.hide_presence", !this.isPresenceHidden);
    this.currentUser.save(["hide_presence"]);
  }

  @action
  setUserStatusClick() {
    this.args.closeUserMenu();

    this.modal.show(UserStatusModal, {
      model: {
        status: this.currentUser.status,
        pauseNotifications: this.currentUser.isInDoNotDisturb(),
        saveAction: (status, pauseNotifications) =>
          this.userStatus.set(status, pauseNotifications),
        deleteAction: () => this.userStatus.clear(),
      },
    });
  }

  @action
  async toggleAnonymous() {
    await ajax(userPath("toggle-anon"), { type: "POST" });
    window.location.reload();
  }
}

<ul aria-labelledby={{@ariaLabelledby}}>
  {{#if this.siteSettings.enable_user_status}}
    <li class="set-user-status">
      <DButton
        @action={{this.setUserStatusClick}}
        class="btn-flat profile-tab-btn"
      >
        {{#if this.currentUser.status}}
          {{emoji this.currentUser.status.emoji}}
          <span class="item-label">
            {{this.currentUser.status.description}}
            {{#if this.currentUser.status.ends_at}}
              {{format-age this.currentUser.status.ends_at}}
            {{/if}}
          </span>
        {{else}}
          {{d-icon "circle-plus"}}
          <span class="item-label">
            {{i18n "user_status.set_custom_status"}}
          </span>
        {{/if}}
      </DButton>
    </li>
  {{/if}}

  <li
    class={{concat-class
      "presence-toggle"
      (unless this.isPresenceHidden "enabled")
    }}
    title={{i18n "presence_toggle.title"}}
  >
    <DButton @action={{this.togglePresence}} class="btn-flat profile-tab-btn">
      {{d-icon (if this.isPresenceHidden "toggle-off" "toggle-on")}}
      <span class="item-label">
        {{#if this.isPresenceHidden}}
          {{i18n "presence_toggle.offline"}}
        {{else}}
          {{i18n "presence_toggle.online"}}
        {{/if}}
      </span>
    </DButton>
  </li>

  <li
    class={{concat-class "do-not-disturb" (if this.isInDoNotDisturb "enabled")}}
  >
    <DButton
      @action={{this.doNotDisturbClick}}
      class="btn-flat profile-tab-btn"
    >
      {{d-icon (if this.isInDoNotDisturb "toggle-on" "toggle-off")}}
      <span class="item-label">
        {{#if this.isInDoNotDisturb}}
          <span>{{i18n "pause_notifications.label"}}</span>
          {{#if this.showDoNotDisturbEndDate}}
            {{format-age this.doNotDisturbDateTime}}
          {{/if}}
        {{else}}
          {{i18n "pause_notifications.label"}}
        {{/if}}
      </span>
    </DButton>
  </li>

  <hr />

  <li class="summary">
    <LinkTo @route="user.summary" @model={{this.currentUser}}>
      {{d-icon "user"}}
      <span class="item-label">
        {{i18n "user.summary.title"}}
      </span>
    </LinkTo>
  </li>

  <li class="activity">
    <LinkTo @route="userActivity" @model={{this.currentUser}}>
      {{d-icon "bars-staggered"}}
      <span class="item-label">
        {{i18n "user.activity_stream"}}
      </span>
    </LinkTo>
  </li>

  {{#if this.currentUser.can_invite_to_forum}}
    <li class="invites">
      <LinkTo @route="userInvited" @model={{this.currentUser}}>
        {{d-icon "user-plus"}}
        <span class="item-label">
          {{i18n "user.invited.title"}}
        </span>
      </LinkTo>
    </li>
  {{/if}}

  <li class="drafts">
    <LinkTo @route="userActivity.drafts" @model={{this.currentUser}}>
      {{d-icon "user_menu.drafts"}}
      <span class="item-label">
        {{#if this.currentUser.draft_count}}
          {{i18n "drafts.label_with_count" count=this.currentUser.draft_count}}
        {{else}}
          {{i18n "drafts.label"}}
        {{/if}}
      </span>
    </LinkTo>
  </li>

  <li class="preferences">
    <LinkTo @route="preferences" @model={{this.currentUser}}>
      {{d-icon "gear"}}
      <span class="item-label">
        {{i18n "user.preferences.title"}}
      </span>
    </LinkTo>
  </li>

  {{#if this.showToggleAnonymousButton}}
    <li
      class={{if
        this.currentUser.is_anonymous
        "disable-anonymous"
        "enable-anonymous"
      }}
    >
      <DButton
        @action={{this.toggleAnonymous}}
        class="btn-flat profile-tab-btn"
      >
        {{#if this.currentUser.is_anonymous}}
          {{d-icon "ban"}}
          <span class="item-label">
            {{i18n "switch_from_anon"}}
          </span>
        {{else}}
          {{d-icon "user-secret"}}
          <span class="item-label">
            {{i18n "switch_to_anon"}}
          </span>
        {{/if}}
      </DButton>
    </li>
  {{/if}}

  {{#each this.extraItems as |item|}}
    <li class={{item.className}}>
      <a href={{item.href}}>
        {{#if item.icon}}
          {{d-icon item.icon}}
        {{/if}}
        <span class="item-label">
          {{item.content}}
        </span>
      </a>
    </li>
  {{/each}}

  <li class="logout">
    <DButton @action={{route-action "logout"}} class="btn-flat profile-tab-btn">
      {{d-icon "right-from-bracket"}}
      <span class="item-label">
        {{i18n "user.log_out"}}
      </span>
    </DButton>
  </li>
</ul>