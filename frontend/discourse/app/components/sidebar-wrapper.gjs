import Sidebar from "discourse/components/sidebar";

const SidebarWrapper = <template>
  <div class="sidebar-wrapper">
    {{! empty div allows for animation }}
    <Sidebar
      @toggleSidebar={{@toggleSidebar}}
      @showSidebar={{@showSidebar}}
      @sidebarEnabled={{@sidebarEnabled}}
    />
  </div>
</template>;

export default SidebarWrapper;
