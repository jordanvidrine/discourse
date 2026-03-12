import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { next } from "@ember/runloop";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import {
  buildEmojiUrl,
  emojiExists,
  emojiReplacementRegex,
  isCustomEmoji,
} from "pretty-text/emoji";
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
const MAX_EMOJI = 5;

const BoostTip = <template>
  <div class="discourse-boosts__tip">
    {{htmlSafe (i18n "discourse_boosts.action_title")}}
    <span class="discourse-boosts__tip-username">
      @{{@data.username}}
    </span>
    {{i18n "discourse_boosts.tip"}}
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

const UNICODE_EMOJI_REGEX = new RegExp(emojiReplacementRegex, "g");

function docStats(doc) {
  let length = 0;
  let emojiCount = 0;
  doc.descendants((node) => {
    if (node.isText) {
      const unicodeMatches = node.text.match(UNICODE_EMOJI_REGEX);
      if (unicodeMatches) {
        emojiCount += unicodeMatches.length;
        length += node.text.replace(UNICODE_EMOJI_REGEX, "x").length;
      } else {
        length += node.text.length;
      }
    } else if (node.type.name === "emoji") {
      length += 1;
      emojiCount += 1;
    }
  });
  return { length, emojiCount };
}

const EXTENSIONS = [
  {
    nodeSpec: {
      doc: { content: "inline*" },
      text: { group: "inline" },
      heading: { attrs: { level: { default: 1 } }, group: "block" },
      bullet_list: { group: "block" },
      ordered_list: { group: "block" },
      code_block: { group: "block", code: true },
      blockquote: { group: "block" },
      paragraph: { group: "block" },
    },
    markSpec: {
      strong: {},
      em: {},
      link: { attrs: { href: { default: "" } } },
      code: {},
    },
    plugins: [
      {
        filterTransaction: (tr) => {
          if (!tr.docChanged) {
            return true;
          }
          const stats = docStats(tr.doc);
          return stats.length <= MAX_LENGTH && stats.emojiCount <= MAX_EMOJI;
        },
      },
      ({
        pmState: { Plugin, PluginKey },
        pmView: { Decoration, DecorationSet },
        getContext,
      }) =>
        new Plugin({
          key: new PluginKey("boost-placeholder"),
          props: {
            decorations(state) {
              if (state.doc.content.size === 0) {
                const text = getContext().placeholder;
                if (text) {
                  const widget = Decoration.widget(0, () => {
                    const span = document.createElement("span");
                    span.className = "discourse-boosts__pm-placeholder";
                    span.textContent = text;
                    return span;
                  });
                  return DecorationSet.create(state.doc, [widget]);
                }
              }
              return DecorationSet.empty;
            },
          },
        }),
    ],
    serializeNode: {
      text(state, node) {
        state.text(node.text);
      },
    },
  },
  BOOST_EMOJI_EXTENSION,
];

export default class BoostInput extends Component {
  @service currentUser;
  @service tooltip;

  @tracked value = "";
  @tracked editorComponent = null;

  store = new KeyValueStore(STORE_NAMESPACE);

  constructor() {
    super(...arguments);
    loadRichEditor().then((component) => (this.editorComponent = component));
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.tooltip.close("discourse-boosts-tip");
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
    return this.value.trim().length > 0;
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
    this.value = event.target.value;
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
    const end = view.state.doc.content.size;
    view.dispatch(view.state.tr.replaceWith(end, end, emojiNode));
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
      {{boundAvatarTemplate this.currentUser.avatar_template "small"}}
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
      {{else}}
        <div class="discourse-boosts__input-placeholder">
          {{this.placeholder}}
        </div>
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
        class="btn-default --success btn-icon-only discourse-boosts__submit"
      />
      <DButton
        @action={{@onClose}}
        @icon="xmark"
        class="btn-default --danger btn-icon-only discourse-boosts__cancel"
      />
    </div>
  </template>
}
