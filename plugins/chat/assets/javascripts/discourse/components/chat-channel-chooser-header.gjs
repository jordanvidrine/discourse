import ComboBoxSelectBoxHeaderComponent from "select-kit/components/combo-box/combo-box-header";

export default class ChatChannelChooserHeader extends ComboBoxSelectBoxHeaderComponent {}

<div class="select-kit-header-wrapper">
  {{#if this.selectedContent}}
    <ChannelTitle @channel={{this.selectedContent}} />
  {{else}}
    {{i18n "chat.incoming_webhooks.channel_placeholder"}}
  {{/if}}

  {{d-icon this.caretIcon class="caret-icon"}}
</div>