import Component from "@glimmer/component";
import { cached } from "@glimmer/tracking";
import { service } from "@ember/service";
import BulkTopicActions from "discourse/components/modal/bulk-topic-actions";
import DismissNew from "discourse/components/modal/dismiss-new";
import DismissReadModal from "discourse/components/modal/dismiss-read";
import PluginOutlet from "discourse/components/plugin-outlet";
import PostListBulkControls from "discourse/components/post-list/bulk-controls";
import Header from "discourse/components/topic-list/header";
import Item from "discourse/components/topic-list/item";
import concatClass from "discourse/helpers/concat-class";
import lazyHash from "discourse/helpers/lazy-hash";
import DAG from "discourse/lib/dag";
import {
  applyMutableValueTransformer,
  applyValueTransformer,
} from "discourse/lib/transformer";
import { eq, or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import HeaderActivityCell from "./header/activity-cell";
import HeaderBulkSelectCell from "./header/bulk-select-cell";
import HeaderLikesCell from "./header/likes-cell";
import HeaderOpLikesCell from "./header/op-likes-cell";
import HeaderPostersCell from "./header/posters-cell";
import HeaderRepliesCell from "./header/replies-cell";
import HeaderTopicCell from "./header/topic-cell";
import HeaderViewsCell from "./header/views-cell";
import ItemActivityCell from "./item/activity-cell";
import ItemBulkSelectCell from "./item/bulk-select-cell";
import ItemLikesCell from "./item/likes-cell";
import ItemOpLikesCell from "./item/op-likes-cell";
import ItemPostersCell from "./item/posters-cell";
import ItemRepliesCell from "./item/replies-cell";
import ItemTopicCell from "./item/topic-cell";
import ItemViewsCell from "./item/views-cell";

export default class TopicList extends Component {
  @service currentUser;
  @service router;
  @service modal;
  @service siteSettings;
  // eslint-disable-next-line discourse/no-unused-services
  @service topicTrackingState; // accessed via `self` variable

  @cached
  get columns() {
    const defaultColumns = new DAG({
      // Allow customizations to replace just a header cell or just an item cell
      onReplaceItem(_, newValue, oldValue) {
        newValue.header ??= oldValue.header;
        newValue.item ??= oldValue.item;
      },
    });

    if (this.bulkSelectEnabled) {
      defaultColumns.add("bulk-select", {
        header: HeaderBulkSelectCell,
        item: ItemBulkSelectCell,
      });
    }

    defaultColumns.add("topic", {
      header: HeaderTopicCell,
      item: ItemTopicCell,
    });

    if (this.args.showPosters) {
      defaultColumns.add("posters", {
        header: HeaderPostersCell,
        item: ItemPostersCell,
      });
    }

    defaultColumns.add("replies", {
      header: HeaderRepliesCell,
      item: ItemRepliesCell,
    });

    if (this.args.order === "likes") {
      defaultColumns.add("likes", {
        header: HeaderLikesCell,
        item: ItemLikesCell,
      });
    } else if (this.args.order === "op_likes") {
      defaultColumns.add("op-likes", {
        header: HeaderOpLikesCell,
        item: ItemOpLikesCell,
      });
    }

    defaultColumns.add("views", {
      header: HeaderViewsCell,
      item: ItemViewsCell,
    });

    defaultColumns.add("activity", {
      header: HeaderActivityCell,
      item: ItemActivityCell,
    });

    const self = this;
    const context = {
      get category() {
        return self.topicTrackingState.get("filterCategory");
      },

      get filter() {
        return self.topicTrackingState.get("filter");
      },
    };

    return applyMutableValueTransformer(
      "topic-list-columns",
      defaultColumns,
      context
    ).resolve();
  }

  get selected() {
    return this.args.bulkSelectHelper?.selected;
  }

  get bulkSelectEnabled() {
    return (
      this.args.bulkSelectHelper?.bulkSelectEnabled && this.args.canBulkSelect
    );
  }

  @cached
  get adaptedBulkSelectHelper() {
    const helper = this.args.bulkSelectHelper;
    if (!helper) {
      return null;
    }

    // Adapt the helper to work with PostListBulkControls
    // PostListBulkControls expects selectedCount and hasSelection
    // Use Proxy to add these properties reactively
    return new Proxy(helper, {
      get(target, prop) {
        if (prop === "selectedCount") {
          return target.selected?.length || 0;
        }
        if (prop === "hasSelection") {
          return (target.selected?.length || 0) > 0;
        }
        return target[prop];
      },
    });
  }

  get canDoBulkActions() {
    return this.currentUser?.canManageTopic && this.selected?.length;
  }

  get toggleInTitle() {
    return !this.bulkSelectEnabled && this.args.canBulkSelect;
  }

  get showTopicPostBadges() {
    return this.args.showTopicPostBadges ?? true;
  }

  get lastVisitedTopic() {
    const { topics, order, ascending, top, hot } = this.args;

    if (
      !this.args.highlightLastVisited ||
      top ||
      hot ||
      ascending ||
      !topics ||
      topics.length === 1 ||
      (order && order !== "activity") ||
      !this.currentUser?.get("previous_visit_at")
    ) {
      return;
    }

    // work backwards
    // this is more efficient cause we keep appending to list
    const start = Math.max(
      topics.findIndex((topic) => !topic.get("pinned")),
      0
    );
    let lastVisitedTopic, topic;

    for (let i = topics.length - 1; i >= start; i--) {
      if (topics[i].get("bumpedAt") > this.currentUser.get("previousVisitAt")) {
        lastVisitedTopic = topics[i];
        break;
      }
      topic = topics[i];
    }

    if (!lastVisitedTopic || !topic) {
      return;
    }

    // end of list that was scanned
    if (topic.get("bumpedAt") > this.currentUser.get("previousVisitAt")) {
      return;
    }

    return lastVisitedTopic;
  }

  get additionalClasses() {
    return applyValueTransformer("topic-list-class", [], {
      topics: this.args.topics,
    });
  }

  @cached
  get topicBulkActions() {
    // If bulkActions are provided via args, use those
    if (this.args.bulkActions) {
      return this.args.bulkActions;
    }

    // Otherwise, generate topic bulk actions from BulkSelectTopicsDropdown logic
    const helper = this.args.bulkSelectHelper;
    if (!helper || !this.selected?.length) {
      return [];
    }

    const selectedTopics = this.selected;
    const actions = [];

    // Dismiss actions
    if (this.router.currentRouteName === "discovery.unread") {
      actions.push({
        label: "topic_bulk_actions.dismiss.name",
        icon: "check",
        action: () => {
          this.modal.show(DismissReadModal, {
            model: {
              title: "topics.bulk.dismiss_read_with_selected",
              count: selectedTopics.length,
              dismissRead: (dismissTopics) =>
                helper.dismissRead(dismissTopics ? "topics" : "posts"),
            },
          });
        },
      });
    }

    if (this.router.currentRouteName === "discovery.new") {
      actions.push({
        label: "topic_bulk_actions.dismiss.name",
        icon: "check",
        action: () => {
          this.modal.show(DismissNew, {
            model: {
              selectedTopics,
              dismissCallback: (dismissTopics) =>
                helper.dismissRead(dismissTopics ? "topics" : "posts"),
            },
          });
        },
      });
    }

    // Category update
    if (!selectedTopics.some((t) => t.isPrivateMessage)) {
      actions.push({
        label: "topic_bulk_actions.update_category.name",
        icon: "pencil",
        action: () => {
          this.modal.show(BulkTopicActions, {
            model: {
              action: "update-category",
              title: i18n("topics.bulk.change_category"),
              description: i18n(
                "topic_bulk_actions.update_category.description"
              ),
              bulkSelectHelper: helper,
              refreshClosure: () => this.args.afterBulkActionComplete?.(),
              allowSilent: true,
            },
          });
        },
      });
    }

    // Notification level
    actions.push({
      label: "topic_bulk_actions.update_notifications.name",
      icon: "d-regular",
      action: () => {
        this.modal.show("bulk-topic-actions", {
          model: {
            action: "update-notifications",
            title: i18n("topics.bulk.notification_level"),
            description: i18n(
              "topic_bulk_actions.update_notifications.description"
            ),
            bulkSelectHelper: helper,
            refreshClosure: () => this.args.afterBulkActionComplete?.(),
          },
        });
      },
    });

    // Close topics
    actions.push({
      label: "topic_bulk_actions.close_topics.name",
      icon: "topic.closed",
      action: () => {
        this.modal.show("bulk-topic-actions", {
          model: {
            action: "close",
            title: i18n("topics.bulk.close_topics"),
            bulkSelectHelper: helper,
            refreshClosure: () => this.args.afterBulkActionComplete?.(),
            allowSilent: true,
          },
        });
      },
    });

    // Archive topics/messages
    if (!selectedTopics.some((t) => t.isPrivateMessage)) {
      actions.push({
        label: "topic_bulk_actions.archive_topics.name",
        icon: "folder",
        action: () => {
          this.modal.show(BulkTopicActions, {
            model: {
              action: "archive",
              title: i18n("topics.bulk.archive_topics"),
              bulkSelectHelper: helper,
              refreshClosure: () => this.args.afterBulkActionComplete?.(),
            },
          });
        },
      });
    } else {
      actions.push({
        label: "topic_bulk_actions.archive_messages.name",
        icon: "box-archive",
        action: () => {
          this.modal.show(BulkTopicActions, {
            model: {
              action: "archive_messages",
              title: i18n("topics.bulk.archive_messages"),
              bulkSelectHelper: helper,
              refreshClosure: () => this.args.afterBulkActionComplete?.(),
            },
          });
        },
      });

      actions.push({
        label: "topic_bulk_actions.move_messages_to_inbox.name",
        icon: "envelope",
        action: () => {
          this.modal.show(BulkTopicActions, {
            model: {
              action: "move_messages_to_inbox",
              title: i18n("topics.bulk.move_messages_to_inbox"),
              bulkSelectHelper: helper,
              refreshClosure: () => this.args.afterBulkActionComplete?.(),
            },
          });
        },
      });
    }

    // Unlist/Relist
    if (
      selectedTopics.some((t) => t.visible) &&
      !selectedTopics.some((t) => t.isPrivateMessage)
    ) {
      actions.push({
        label: "topic_bulk_actions.unlist_topics.name",
        icon: "far-eye-slash",
        action: () => {
          this.modal.show(BulkTopicActions, {
            model: {
              action: "unlist",
              title: i18n("topics.bulk.unlist_topics"),
              bulkSelectHelper: helper,
              refreshClosure: () => this.args.afterBulkActionComplete?.(),
            },
          });
        },
      });
    }

    if (
      selectedTopics.some((t) => !t.visible) &&
      !selectedTopics.some((t) => t.isPrivateMessage)
    ) {
      actions.push({
        label: "topic_bulk_actions.relist_topics.name",
        icon: "far-eye",
        action: () => {
          this.modal.show(BulkTopicActions, {
            model: {
              action: "relist",
              title: i18n("topics.bulk.relist_topics"),
              bulkSelectHelper: helper,
              refreshClosure: () => this.args.afterBulkActionComplete?.(),
            },
          });
        },
      });
    }

    // Tags
    if (this.siteSettings.tagging_enabled && this.currentUser?.canManageTopic) {
      actions.push({
        label: "topic_bulk_actions.append_tags.name",
        icon: "tag",
        action: () => {
          this.modal.show(BulkTopicActions, {
            model: {
              action: "append-tags",
              title: i18n("topics.bulk.choose_append_tags"),
              bulkSelectHelper: helper,
              refreshClosure: () => this.args.afterBulkActionComplete?.(),
            },
          });
        },
      });

      actions.push({
        label: "topic_bulk_actions.replace_tags.name",
        icon: "tag",
        action: () => {
          this.modal.show(BulkTopicActions, {
            model: {
              action: "replace-tags",
              title: i18n("topics.bulk.change_tags"),
              bulkSelectHelper: helper,
              refreshClosure: () => this.args.afterBulkActionComplete?.(),
            },
          });
        },
      });

      actions.push({
        label: "topic_bulk_actions.remove_tags.name",
        icon: "tag",
        action: () => {
          this.modal.show(BulkTopicActions, {
            model: {
              action: "remove-tags",
              title: i18n("topics.bulk.remove_tags"),
              bulkSelectHelper: helper,
              refreshClosure: () => this.args.afterBulkActionComplete?.(),
            },
          });
        },
      });
    }

    // Delete (staff only)
    if (this.currentUser?.staff) {
      actions.push({
        label: "topic_bulk_actions.delete_topics.name",
        icon: "trash-can",
        action: () => {
          this.modal.show(BulkTopicActions, {
            model: {
              action: "delete",
              title: i18n("topics.bulk.delete"),
              bulkSelectHelper: helper,
              refreshClosure: () => this.args.afterBulkActionComplete?.(),
            },
          });
        },
      });
    }

    // Reset bump dates
    actions.push({
      label: "topic_bulk_actions.reset_bump_dates.name",
      icon: "anchor",
      action: () => {
        this.modal.show("bulk-topic-actions", {
          model: {
            action: "reset-bump-dates",
            title: i18n("topics.bulk.reset_bump_dates"),
            description: i18n(
              "topic_bulk_actions.reset_bump_dates.description"
            ),
            bulkSelectHelper: helper,
            refreshClosure: () => this.args.afterBulkActionComplete?.(),
          },
        });
      },
    });

    // Defer
    if (this.currentUser?.user_option?.enable_defer) {
      actions.push({
        label: "topic_bulk_actions.defer.name",
        icon: "circle",
        action: () => {
          this.modal.show(BulkTopicActions, {
            model: {
              action: "defer",
              title: i18n("topics.bulk.defer"),
              description: i18n("topic_bulk_actions.defer.description"),
              bulkSelectHelper: helper,
              refreshClosure: () => this.args.afterBulkActionComplete?.(),
            },
          });
        },
      });
    }

    return actions;
  }

  <template>
    {{! template-lint-disable table-groups }}
    {{#if this.bulkSelectEnabled}}
      <PostListBulkControls
        @bulkSelectHelper={{this.adaptedBulkSelectHelper}}
        @bulkActions={{this.topicBulkActions}}
      />
    {{/if}}
    <table
      class={{concatClass
        "topic-list"
        (if this.bulkSelectEnabled "sticky-header bulk-select-enabled")
        this.additionalClasses
      }}
      aria-labelledby={{@ariaLabelledby}}
      ...attributes
    >
      <caption class="sr-only">{{i18n "sr_topic_list_caption"}}</caption>
      <thead class="topic-list-header">
        <Header
          @columns={{this.columns}}
          @canBulkSelect={{@canBulkSelect}}
          @toggleInTitle={{this.toggleInTitle}}
          @category={{@category}}
          @hideCategory={{@hideCategory}}
          @order={{@order}}
          @changeSort={{@changeSort}}
          @ascending={{@ascending}}
          @sortable={{@changeSort}}
          @listTitle={{or @listTitle "topic.title"}}
          @bulkSelectHelper={{@bulkSelectHelper}}
          @bulkSelectEnabled={{this.bulkSelectEnabled}}
          @canDoBulkActions={{this.canDoBulkActions}}
        />
      </thead>

      <PluginOutlet
        @name="before-topic-list-body"
        @outletArgs={{lazyHash
          topics=@topics
          selected=this.selected
          bulkSelectEnabled=this.bulkSelectEnabled
          lastVisitedTopic=this.lastVisitedTopic
          discoveryList=@discoveryList
          hideCategory=@hideCategory
        }}
      />

      <tbody class="topic-list-body">
        {{#each @topics as |topic index|}}
          <Item
            @columns={{this.columns}}
            @topic={{topic}}
            @bulkSelectHelper={{@bulkSelectHelper}}
            @bulkSelectEnabled={{this.bulkSelectEnabled}}
            @showTopicPostBadges={{this.showTopicPostBadges}}
            @hideCategory={{@hideCategory}}
            @expandGloballyPinned={{@expandGloballyPinned}}
            @expandAllPinned={{@expandAllPinned}}
            @lastVisitedTopic={{this.lastVisitedTopic}}
            @selected={{this.selected}}
            @tagsForUser={{@tagsForUser}}
            @focusLastVisitedTopic={{@focusLastVisitedTopic}}
            @index={{index}}
          />

          {{#if (eq topic this.lastVisitedTopic)}}
            <tr class="topic-list-item-separator">
              <td class="topic-list-data" colspan="6">
                <span>
                  {{i18n "topics.new_messages_marker"}}
                </span>
              </td>
            </tr>
          {{/if}}

          <PluginOutlet
            @name="after-topic-list-item"
            @outletArgs={{lazyHash topic=topic index=index}}
            @connectorTagName="tr"
          />
        {{/each}}
      </tbody>

      <PluginOutlet
        @name="after-topic-list-body"
        @outletArgs={{lazyHash
          topics=@topics
          selected=this.selected
          bulkSelectEnabled=this.bulkSelectEnabled
          lastVisitedTopic=this.lastVisitedTopic
          discoveryList=@discoveryList
          hideCategory=@hideCategory
        }}
      />
    </table>
  </template>
}
