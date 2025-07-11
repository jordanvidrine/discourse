import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import HomeLogo from "discourse/components/header/home-logo";
import SidebarToggle from "discourse/components/header/sidebar-toggle";
import PluginOutlet from "discourse/components/plugin-outlet";
import AnonymousSections from "./anonymous/sections";
import UserSections from "./user/sections";

export default class SidebarSections extends Component {
  @service site;
  @service navigationMenu;

  @action
  toggleNavigationMenu(override = null) {
    if (override === "sidebar") {
      return this.toggleSidebar();
    }

    if (override === "hamburger") {
      return this.toggleHamburger();
    }

    if (this.args.sidebarEnabled && !this.site.narrowDesktopView) {
      this.toggleSidebar();
    } else {
      this.toggleHamburger();
    }
  }

  @action
  toggleHamburger() {
    this.header.hamburgerVisible = !this.header.hamburgerVisible;
    this.toggleBodyScrolling(this.header.hamburgerVisible);
    this.args.animateMenu();
  }

  @action
  toggleSidebar() {
    this.args.toggleSidebar();
    this.args.animateMenu();
  }

  get sidebarIcon() {
    if (this.navigationMenu.isDesktopDropdownMode) {
      return "discourse-sidebar";
    }

    return "bars";
  }

  <template>
    <div class="sidebar-sections">
      <div class="home-logo-wrapper-outlet">
        <PluginOutlet @name="home-logo-wrapper">
          <HomeLogo @minimized={{this.minimized}} />
        </PluginOutlet>
        {{#if this.site.desktopView}}
          {{#if @sidebarEnabled}}
            <SidebarToggle
              @toggleNavigationMenu={{this.toggleNavigationMenu}}
              @showSidebar={{@showSidebar}}
              @icon={{this.sidebarIcon}}
            />
          {{/if}}
        {{/if}}
      </div>
      {{#if @currentUser}}
        <UserSections
          @collapsableSections={{@collapsableSections}}
          @panel={{@panel}}
          @hideApiSections={{@hideApiSections}}
          @toggleNavigationMenu={{@toggleNavigationMenu}}
        />
      {{else}}
        <AnonymousSections
          @collapsableSections={{@collapsableSections}}
          @toggleNavigationMenu={{@toggleNavigationMenu}}
        />
      {{/if}}
    </div>
  </template>
}
