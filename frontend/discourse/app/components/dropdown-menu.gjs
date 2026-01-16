import { hash } from "@ember/helper";

const DropdownItem = <template>
  <li class="dropdown-menu__item" ...attributes>{{yield}}</li>
</template>;

const DropdownDivider = <template>
  <li class="dropdown-menu__item dropdown-menu__divider" ...attributes></li>
</template>;

const DropdownMenu = <template>
  <ul class="dropdown-menu" ...attributes>
    {{yield (hash item=DropdownItem divider=DropdownDivider)}}
  </ul>
</template>;

export default DropdownMenu;
