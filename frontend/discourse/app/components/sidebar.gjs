import Component from "@glimmer/component";
import { service } from "@ember/service";
import HomeLogo from "discourse/components/header/home-logo";
import SidebarToggle from "discourse/components/header/sidebar-toggle";
import PluginOutlet from "discourse/components/plugin-outlet";
import ApiPanels from "discourse/components/sidebar/api-panels";
import Footer from "discourse/components/sidebar/footer";
import Sections from "discourse/components/sidebar/sections";
import SwitchPanelButtons from "discourse/components/sidebar/switch-panel-buttons";
import bodyClass from "discourse/helpers/body-class";
import { bind } from "discourse/lib/decorators";
import { applyValueTransformer } from "discourse/lib/transformer";

export default class Sidebar extends Component {
  @service site;
  @service siteSettings;
  @service currentUser;
  @service sidebarState;
  @service header;
  @service navigationMenu;

  constructor() {
    super(...arguments);

    if (this.site.mobileView) {
      document.addEventListener("click", this.collapseSidebar);
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    if (this.site.mobileView) {
      document.removeEventListener("click", this.collapseSidebar);
    }
  }

  get showSwitchPanelButtonsOnTop() {
    return this.siteSettings.default_sidebar_switch_panel_position === "top";
  }

  get switchPanelButtons() {
    if (
      !this.sidebarState.displaySwitchPanelButtons ||
      this.sidebarState.panels.length === 1 ||
      !this.currentUser
    ) {
      return [];
    }

    return this.sidebarState.panels.filter(
      (panel) => panel !== this.sidebarState.currentPanel && !panel.hidden
    );
  }

  @bind
  collapseSidebar(event) {
    let shouldCollapseSidebar = false;

    const isClickWithinSidebar = event.composedPath().some((element) => {
      if (
        element?.className !== "sidebar-section-header-caret" &&
        ["A", "BUTTON"].includes(element.nodeName)
      ) {
        shouldCollapseSidebar = true;
        return true;
      }

      return element.className && element.className === "sidebar-wrapper";
    });

    if (shouldCollapseSidebar || !isClickWithinSidebar) {
      this.args.toggleSidebar();
    }
  }

  get sidebarIcon() {
    if (this.navigationMenu.isDesktopDropdownMode) {
      return "discourse-sidebar";
    }

    return "bars";
  }

  get minimized() {
    return applyValueTransformer(
      "home-logo-minimized",
      this.header.topicInfoVisible,
      {
        topicInfo: this.header.topicInfo,
        sidebarEnabled: this.args.sidebarEnabled,
        showSidebar: this.args.showSidebar,
      }
    );
  }

  get bodyClass() {
    if (this.args.showSidebar) {
      return "has-sidebar-page";
    } else {
      return "sidebar-minimized";
    }
  }

  <template>
    {{bodyClass this.bodyClass}}

    <section id="d-sidebar" class="sidebar-container">
      <div class="d-sidebar-header">
        {{#if @showSidebar}}
          <div class="home-logo-wrapper-outlet">
            <PluginOutlet @name="home-logo-wrapper">
              <HomeLogo @minimized={{this.minimized}} />
            </PluginOutlet>
          </div>
        {{/if}}
        {{#if this.site.desktopView}}
          {{#if @sidebarEnabled}}
            <SidebarToggle
              @toggleNavigationMenu={{@toggleSidebar}}
              @showSidebar={{@showSidebar}}
              @icon={{this.sidebarIcon}}
            />
          {{/if}}
        {{/if}}
      </div>
      {{#if @showSidebar}}
        {{#if this.showSwitchPanelButtonsOnTop}}
          <SwitchPanelButtons @buttons={{this.switchPanelButtons}} />
        {{/if}}

        <PluginOutlet @name="before-sidebar-sections" />

        {{#if this.sidebarState.showMainPanel}}
          <Sections
            @currentUser={{this.currentUser}}
            @collapsableSections={{true}}
            @panel={{this.sidebarState.currentPanel}}
          />
        {{else}}
          <ApiPanels
            @currentUser={{this.currentUser}}
            @collapsableSections={{true}}
          />
        {{/if}}

        <PluginOutlet @name="after-sidebar-sections" />

        {{#unless this.showSwitchPanelButtonsOnTop}}
          <SwitchPanelButtons @buttons={{this.switchPanelButtons}} />
        {{/unless}}

        <Footer />
      {{/if}}
    </section>
  </template>
}
