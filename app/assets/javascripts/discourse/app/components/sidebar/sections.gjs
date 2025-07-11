import HomeLogo from "discourse/components/header/home-logo";
import PluginOutlet from "discourse/components/plugin-outlet";
import AnonymousSections from "./anonymous/sections";
import UserSections from "./user/sections";

const SidebarSections = <template>
  <div class="sidebar-sections">
    <div class="home-logo-wrapper-outlet">
      <PluginOutlet @name="home-logo-wrapper">
        <HomeLogo @minimized={{this.minimized}} />
      </PluginOutlet>
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
</template>;

export default SidebarSections;
