import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array, fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import DMenu from "discourse/float-kit/components/d-menu";
import boundAvatarTemplate from "discourse/helpers/bound-avatar-template";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import createBoost from "../lib/create-boost";
import BoostInput from "./boost-input";

export default class BoostsList extends Component {
  @service currentUser;

  @tracked selectedBoostId = null;

  get boosts() {
    return this.args.post.boosts || [];
  }

  get canBoost() {
    return this.args.post.can_boost;
  }

  @action
  onRegisterApi(api) {
    this.dMenu = api;
  }

  @action
  toggleDelete(boostId) {
    if (this.selectedBoostId === boostId) {
      this.selectedBoostId = null;
    } else {
      this.selectedBoostId = boostId;
    }
  }

  @action
  async deleteBoost(boostId) {
    const previousBoosts = this.boosts;
    const previousCanBoost = this.args.post.can_boost;
    const boost = this.boosts.find((b) => b.id === boostId);
    this.args.post.boosts = this.boosts.filter((b) => b.id !== boostId);
    this.selectedBoostId = null;

    if (boost?.user?.id === this.currentUser?.id) {
      this.args.post.can_boost = true;
    }

    try {
      await ajax(`/discourse-boosts/boosts/${boostId}`, { type: "DELETE" });
    } catch (e) {
      this.args.post.boosts = previousBoosts;
      this.args.post.can_boost = previousCanBoost;
      popupAjaxError(e);
    }
  }

  @action
  async addBoostWithRaw(raw) {
    this.dMenu?.close();
    await createBoost(this.args.post, raw, this.currentUser);
  }

  <template>
    {{#if this.boosts.length}}
      <div class="discourse-boosts">
        <div class="discourse-boosts__list">
          {{#each this.boosts as |boost|}}
            <span
              class={{concatClass
                "discourse-boosts__bubble"
                (if boost.can_delete "--deletable")
                (if (eq this.selectedBoostId boost.id) "--selected")
              }}
            >
              <a data-user-card={{boost.user.username}}>{{boundAvatarTemplate
                  boost.user.avatar_template
                  "tiny"
                }}</a>
              {{#if boost.can_delete}}
                <button
                  type="button"
                  class="discourse-boosts__cooked btn-transparent"
                  {{on "click" (fn this.toggleDelete boost.id)}}
                >{{htmlSafe boost.cooked}}</button>
              {{else}}
                <span class="discourse-boosts__cooked">{{htmlSafe
                    boost.cooked
                  }}</span>
              {{/if}}
              {{#if (eq this.selectedBoostId boost.id)}}
                <button
                  type="button"
                  class="discourse-boosts__delete btn-transparent --danger"
                  aria-label={{i18n "discourse_boosts.delete_boost"}}
                  {{on "click" (fn this.deleteBoost boost.id)}}
                >{{icon "trash-can"}}</button>
              {{/if}}
            </span>
          {{/each}}

          {{#if this.canBoost}}
            <DMenu
              @identifier="discourse-boosts"
              @icon="rocket"
              @title={{i18n "discourse_boosts.boost_button_title"}}
              @modalForMobile={{false}}
              @onRegisterApi={{this.onRegisterApi}}
              @triggerClass="discourse-boosts__add-btn btn-flat"
              @triggers={{hash
                mobile=(array "click")
                desktop=(array "delayed-hover" "click")
              }}
            >
              <:content>
                <BoostInput
                  @post={{@post}}
                  @onSubmit={{this.addBoostWithRaw}}
                  @onClose={{this.dMenu.close}}
                />
              </:content>
            </DMenu>
          {{/if}}
        </div>
      </div>
    {{/if}}
  </template>
}
