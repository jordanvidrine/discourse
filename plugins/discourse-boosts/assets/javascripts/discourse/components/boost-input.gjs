import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { next } from "@ember/runloop";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { buildEmojiUrl, emojiExists, isCustomEmoji } from "pretty-text/emoji";
import DButton from "discourse/components/d-button";
import EmojiPicker from "discourse/components/emoji-picker";
import boundAvatarTemplate from "discourse/helpers/bound-avatar-template";
import KeyValueStore from "discourse/lib/key-value-store";
import loadRichEditor from "discourse/lib/load-rich-editor";
import { emojiOptions } from "discourse/lib/text";
import { not } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

const STORE_NAMESPACE = "discourse_boosts_";
const TIP_SEEN_KEY = "tip_seen";
const MAX_LENGTH = 16;

const BoostTip = <template>
  <div class="discourse-boosts__tip">
    {{htmlSafe (i18n "discourse_boosts.action_title")}}
    <span class="discourse-boosts__tip-username">
      @{{htmlSafe @data.username}}
    </span>
    {{htmlSafe (i18n "discourse_boosts.tip" username=@data.username)}}
  </div>
</template>;

const BOOST_EMOJI_EXTENSION = {
  nodeSpec: {
    emoji: {
      attrs: { code: {} },
      inline: true,
      group: "inline",
      draggable: true,
      selectable: false,
      parseDOM: [
        {
          tag: "img.emoji",
          getAttrs: (dom) => ({
            code: dom.getAttribute("alt").replace(/:/g, ""),
          }),
          priority: 60,
        },
      ],
      toDOM: (node) => {
        const opts = emojiOptions();
        const code = node.attrs.code.toLowerCase();
        const title = `:${code}:`;
        const src = buildEmojiUrl(code, opts);

        return [
          "img",
          {
            class: isCustomEmoji(code, opts) ? "emoji emoji-custom" : "emoji",
            alt: title,
            title,
            src,
          },
        ];
      },
    },
  },

  inputRules: [
    {
      match: /(^|\W):([^:]+):$/,
      handler: (state, match, start, end) => {
        if (emojiExists(match[2])) {
          const emojiStart = start + match[1].length;
          const emojiNode = state.schema.nodes.emoji.create({
            code: match[2],
          });
          return state.tr.replaceWith(emojiStart, end, emojiNode);
        }
      },
      options: { undoable: false },
    },
  ],

  parse: {
    emoji: {
      node: "emoji",
      getAttrs: (token) => ({
        code: token.attrGet("alt").slice(1, -1),
      }),
    },
  },

  serializeNode: {
    emoji(state, node) {
      state.write(`:${node.attrs.code}:`);
    },
  },
};

const EXTENSIONS = [
  {
    nodeSpec: {
      doc: { content: "inline*" },
      text: { group: "inline" },
    },
    serializeNode: {
      text(state, node) {
        state.text(node.text);
      },
    },
  },
  BOOST_EMOJI_EXTENSION,
];

export default class BoostInput extends Component {
  @service tooltip;

  @tracked value = "";
  @tracked editorComponent = null;

  store = new KeyValueStore(STORE_NAMESPACE);

  constructor() {
    super(...arguments);
    loadRichEditor().then((component) => (this.editorComponent = component));
  }

  @action
  maybeShowTip(element) {
    if (this.store.get(TIP_SEEN_KEY)) {
      return;
    }

    this.store.set({ key: TIP_SEEN_KEY, value: true });

    next(() => {
      this.tooltip.show(element, {
        identifier: "discourse-boosts-tip",
        placement: "top",
        component: BoostTip,
        data: {
          username: this.args.post.username,
        },
      });
    });
  }

  get editorKeymap() {
    return {
      Enter: () => {
        this.submit();
        return true;
      },
      Escape: () => {
        this.args.onClose();
        return true;
      },
    };
  }

  get canSubmit() {
    return this.value.trim().length > 0 && this.value.length <= MAX_LENGTH;
  }

  get placeholder() {
    return i18n("discourse_boosts.boost_input_placeholder", {
      username: this.args.post.username,
    });
  }

  @action
  onEditorSetup(textManipulation) {
    this.textManipulation = textManipulation;
    textManipulation.focus();
  }

  @action
  onChange(event) {
    const val = event.target.value;
    if (val.length <= MAX_LENGTH) {
      this.value = val;
    } else {
      this.textManipulation?.putCursorAtEnd();
    }
  }

  @action
  submit() {
    if (this.canSubmit) {
      this.args.onSubmit(this.value.trim());
    }
  }

  @action
  didSelectEmoji(emoji) {
    const view = this.textManipulation?.view;
    if (!view) {
      return;
    }

    const emojiNode = view.state.schema.nodes.emoji.create({ code: emoji });
    const { from, to } = view.state.selection;
    view.dispatch(view.state.tr.replaceWith(from, to, emojiNode));
  }

  @action
  focusEditor() {
    next(() => this.textManipulation?.focus());
  }

  <template>
    <div
      class="discourse-boosts__input-container"
      {{didInsert this.maybeShowTip}}
    >
      {{boundAvatarTemplate @post.avatar_template "small"}}
      {{#if this.editorComponent}}
        <this.editorComponent
          @class="discourse-boosts__input"
          @includeDefault={{false}}
          @extensions={{EXTENSIONS}}
          @placeholder={{this.placeholder}}
          @change={{this.onChange}}
          @onSetup={{this.onEditorSetup}}
          @keymap={{this.editorKeymap}}
        />
      {{/if}}
      <EmojiPicker
        @didSelectEmoji={{this.didSelectEmoji}}
        @onClose={{this.focusEditor}}
        @btnClass="btn-transparent discourse-boosts__emoji-btn"
        @context="boost"
        @modalForMobile={{false}}
      />
      <DButton
        @action={{this.submit}}
        @icon="check"
        @disabled={{not this.canSubmit}}
        class="btn-default --success btn-icon-only btn-default discourse-boosts__submit"
      />
      <DButton
        @action={{@onClose}}
        @icon="xmark"
        class="btn-default --danger btn-icon-only discourse-boosts__cancel"
      />
    </div>
  </template>
}
