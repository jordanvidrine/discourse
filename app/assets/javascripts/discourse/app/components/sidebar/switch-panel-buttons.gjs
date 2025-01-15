import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { eq } from "truth-helpers";
import DButton from "discourse/components/d-button";

export default class SwitchPanelButtons extends Component {
  @service router;
  @service sidebarState;

  @tracked isSwitching = false;

  @action
  async switchPanel(panel) {
    this.isSwitching = true;
    this.sidebarState.currentPanel.lastKnownURL = this.router.currentURL;

    const destination = panel?.switchButtonDefaultUrl || panel?.lastKnownURL;
    if (!destination) {
      return;
    }

    try {
      await this.router.transitionTo(destination).followRedirects();
      this.sidebarState.setPanel(panel.key);
    } catch (e) {
      if (e.name !== "TransitionAborted") {
        throw e;
      }
    } finally {
      this.isSwitching = false;
    }
  }

  <template>
    {{#each @buttons as |button|}}
      <div class="sidebar__panel-switch-container">
        <div class="sidebar__panel-button-wrapper">
          {{#if (eq button.key "chat")}}
            <DButton
              class="btn-default"
              @translatedLabel="Topics"
              @disabled="true"
            />
          {{/if}}
          <DButton
            @action={{fn this.switchPanel button}}
            @disabled={{this.isSwitching}}
            @translatedLabel={{button.switchButtonLabel}}
            data-key={{button.key}}
            class="btn-transparent sidebar__panel-switch-button"
          />
          {{#if (eq button.key "main")}}
            <DButton
              class="btn-default"
              @translatedLabel="Chat"
              @disabled="true"
            />
          {{/if}}
        </div>
      </div>
    {{/each}}
  </template>
}
