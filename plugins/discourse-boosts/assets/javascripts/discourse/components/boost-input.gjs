import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
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

const UNICODE_EMOJI_REGEX = new RegExp(emojiReplacementRegex, "g");
const EMOJI_SHORTCODE_REGEX = /(^|\W):([^:]+):/;

function getStats(element) {
  let length = 0;
  let emojiCount = 0;

  for (const node of element.childNodes) {
    if (node.nodeType === Node.TEXT_NODE) {
      const text = node.textContent;
      const unicodeMatches = text.match(UNICODE_EMOJI_REGEX);
      if (unicodeMatches) {
        emojiCount += unicodeMatches.length;
        length += text.replace(UNICODE_EMOJI_REGEX, "x").length;
      } else {
        length += text.length;
      }
    } else if (node.nodeName === "IMG" && node.classList.contains("emoji")) {
      length += 1;
      emojiCount += 1;
    }
  }

  return { length, emojiCount };
}

function serialize(element) {
  let result = "";

  for (const node of element.childNodes) {
    if (node.nodeType === Node.TEXT_NODE) {
      result += node.textContent;
    } else if (node.nodeName === "IMG" && node.classList.contains("emoji")) {
      result += node.alt;
    }
  }

  return result;
}

function createEmojiImg(code) {
  const opts = emojiOptions();
  const title = `:${code}:`;
  const src = buildEmojiUrl(code, opts);
  const img = document.createElement("img");
  img.className = isCustomEmoji(code, opts) ? "emoji emoji-custom" : "emoji";
  img.alt = title;
  img.title = title;
  img.src = src;
  return img;
}

function placeCursorAtEnd(element) {
  const range = document.createRange();
  const sel = window.getSelection();
  range.selectNodeContents(element);
  range.collapse(false);
  sel.removeAllRanges();
  sel.addRange(range);
}

export default class BoostInput extends Component {
  @service currentUser;
  @service tooltip;

  @tracked value = "";
  @tracked canAddEmoji = true;

  store = new KeyValueStore(STORE_NAMESPACE);
  #previousHTML = "";

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

  get canSubmit() {
    return this.value.trim().length > 0;
  }

  get placeholder() {
    return i18n("discourse_boosts.boost_input_placeholder", {
      username: this.args.post.username,
    });
  }

  @action
  setupEditor(element) {
    this.editor = element;
    next(() => element.focus());
  }

  @action
  onInput() {
    this.#processEmojiShortcodes();

    const stats = getStats(this.editor);
    if (stats.length > MAX_LENGTH || stats.emojiCount > MAX_EMOJI) {
      this.editor.innerHTML = this.#previousHTML;
      placeCursorAtEnd(this.editor);
      return;
    }

    this.#previousHTML = this.editor.innerHTML;
    this.value = serialize(this.editor);
    this.#updateCanAddEmoji(stats);
  }

  @action
  onKeyDown(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      this.submit();
    } else if (event.key === "Escape") {
      event.preventDefault();
      this.args.onClose();
    }
  }

  @action
  onPaste(event) {
    event.preventDefault();
    const text = event.clipboardData.getData("text/plain");
    document.execCommand("insertText", false, text);
  }

  @action
  submit() {
    if (this.canSubmit) {
      this.args.onSubmit(this.value.trim());
    }
  }

  @action
  didSelectEmoji(emoji) {
    const stats = getStats(this.editor);
    const needsSpace = this.editor.childNodes.length > 0;
    const extraLength = needsSpace ? 2 : 1;

    if (
      stats.length + extraLength > MAX_LENGTH ||
      stats.emojiCount + 1 > MAX_EMOJI
    ) {
      return;
    }

    if (needsSpace) {
      this.editor.appendChild(document.createTextNode(" "));
    }

    this.editor.appendChild(createEmojiImg(emoji));
    placeCursorAtEnd(this.editor);
    this.#previousHTML = this.editor.innerHTML;
    this.value = serialize(this.editor);
    this.#updateCanAddEmoji(getStats(this.editor));
  }

  @action
  focusEditor() {
    next(() => this.editor?.focus());
  }

  #updateCanAddEmoji(stats) {
    const spaceNeeded = this.editor.childNodes.length > 0 ? 2 : 1;
    this.canAddEmoji =
      stats.length + spaceNeeded <= MAX_LENGTH && stats.emojiCount < MAX_EMOJI;
  }

  #processEmojiShortcodes() {
    const walker = document.createTreeWalker(this.editor, NodeFilter.SHOW_TEXT);

    let node;
    while ((node = walker.nextNode())) {
      const match = node.textContent.match(EMOJI_SHORTCODE_REGEX);
      if (match && emojiExists(match[2])) {
        const code = match[2];
        const emojiStart = match.index + match[1].length;
        const emojiEnd = emojiStart + code.length + 2;
        const beforeText = node.textContent.slice(0, emojiStart);
        const afterText = node.textContent.slice(emojiEnd);
        const img = createEmojiImg(code);
        const parent = node.parentNode;

        if (afterText) {
          parent.insertBefore(
            document.createTextNode(afterText),
            node.nextSibling
          );
        }

        parent.insertBefore(img, node.nextSibling);

        if (beforeText) {
          node.textContent = beforeText;
        } else {
          parent.removeChild(node);
        }

        const range = document.createRange();
        const sel = window.getSelection();
        range.setStartAfter(img);
        range.collapse(true);
        sel.removeAllRanges();
        sel.addRange(range);

        break;
      }
    }
  }

  <template>
    <div
      class="discourse-boosts__input-container"
      {{didInsert this.maybeShowTip}}
    >
      {{boundAvatarTemplate this.currentUser.avatar_template "small"}}
      {{! template-lint-disable no-invalid-interactive }}
      <div
        class="discourse-boosts__input"
        contenteditable="true"
        data-placeholder={{this.placeholder}}
        {{didInsert this.setupEditor}}
        {{on "input" this.onInput}}
        {{on "keydown" this.onKeyDown}}
        {{on "paste" this.onPaste}}
      ></div>
      <EmojiPicker
        @didSelectEmoji={{this.didSelectEmoji}}
        @onClose={{this.focusEditor}}
        @btnClass="btn-transparent discourse-boosts__emoji-btn"
        @context="boost"
        @modalForMobile={{false}}
        @disabled={{not this.canAddEmoji}}
      />
      <DButton
        @action={{this.submit}}
        @icon="check"
        @disabled={{not this.canSubmit}}
        @ariaLabel="discourse_boosts.submit"
        @title="discourse_boosts.submit"
        class="btn-default --success btn-icon-only discourse-boosts__submit"
      />
      <DButton
        @action={{@onClose}}
        @icon="xmark"
        @ariaLabel="discourse_boosts.cancel"
        @title="discourse_boosts.cancel"
        class="btn-default --danger btn-icon-only discourse-boosts__cancel"
      />
    </div>
  </template>
}
