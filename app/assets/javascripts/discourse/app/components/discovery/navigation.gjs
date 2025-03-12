import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import ReorderCategories from "discourse/components/modal/reorder-categories";
import { calculateFilterMode } from "discourse/lib/filter-mode";
import { TRACKED_QUERY_PARAM_VALUE } from "discourse/lib/topic-list-tracked-filter";
import DiscourseURL from "discourse/lib/url";
import Category from "discourse/models/category";

export default class DiscoveryNavigation extends Component {
  @service router;
  @service currentUser;
  @service modal;

  get filterMode() {
    return calculateFilterMode({
      category: this.args.category,
      filterType: this.args.filterType,
      noSubcategories: this.args.noSubcategories,
    });
  }

  get skipCategoriesNavItem() {
    return this.router.currentRoute.queryParams.f === TRACKED_QUERY_PARAM_VALUE;
  }

  get canCreateTopic() {
    return this.currentUser?.can_create_topic;
  }

  get bodyClass() {
    if (this.args.tag) {
      return [
        "tags-page",
        this.args.additionalTags ? "tags-intersection" : null,
      ]
        .filter(Boolean)
        .join(" ");
    } else if (this.filterMode === "categories") {
      return "navigation-categories";
    } else if (this.args.category) {
      return "navigation-category";
    } else {
      return "navigation-topics";
    }
  }

  @action
  editCategory() {
    DiscourseURL.routeTo(`/c/${Category.slugFor(this.args.category)}/edit`);
  }

  @action
  createCategory() {
    this.router.transitionTo("newCategory");
  }

  @action
  reorderCategories() {
    this.modal.show(ReorderCategories);
  }
}

<AddCategoryTagClasses
  @category={{@category}}
  @tags={{if @tag (array @tag.id)}}
/>

{{#if @category}}
  <PluginOutlet
    @name="above-category-heading"
    @outletArgs={{hash category=@category tag=@tag}}
  />

  <section class="category-heading">
    {{#if @category.uploaded_logo.url}}
      <CategoryLogo @category={{@category}} />
      {{#if @category.description}}
        <p>{{dir-span @category.description htmlSafe="true"}}</p>
      {{/if}}
    {{/if}}

    <span>
      <PluginOutlet
        @name="category-heading"
        @connectorTagName="div"
        @outletArgs={{hash category=@category tag=@tag}}
      />
    </span>
  </section>
{{/if}}

{{body-class this.bodyClass}}

<section
  class={{concat-class
    "navigation-container"
    (if @category "category-navigation")
  }}
>
  <DNavigation
    @category={{@category}}
    @tag={{@tag}}
    @additionalTags={{@additionalTags}}
    @filterMode={{this.filterMode}}
    @noSubcategories={{@noSubcategories}}
    @canCreateTopic={{this.canCreateTopic}}
    @canCreateTopicOnTag={{@canCreateTopicOnTag}}
    @createTopic={{@createTopic}}
    @createTopicDisabled={{@createTopicDisabled}}
    @draftCount={{this.currentUser.draft_count}}
    @editCategory={{this.editCategory}}
    @showCategoryAdmin={{@showCategoryAdmin}}
    @createCategory={{this.createCategory}}
    @reorderCategories={{this.reorderCategories}}
    @canBulkSelect={{@canBulkSelect}}
    @bulkSelectHelper={{@bulkSelectHelper}}
    @skipCategoriesNavItem={{this.skipCategoriesNavItem}}
    @toggleInfo={{@toggleTagInfo}}
    @tagNotification={{@tagNotification}}
    @model={{@model}}
    @showDismissRead={{@showDismissRead}}
    @showResetNew={{@showResetNew}}
    @dismissRead={{@dismissRead}}
    @resetNew={{@resetNew}}
  />

  {{#if @category}}
    <PluginOutlet
      @name="category-navigation"
      @connectorTagName="div"
      @outletArgs={{hash category=@category tag=@tag}}
    />
  {{/if}}

  {{#if @tag}}
    <PluginOutlet
      @name="tag-navigation"
      @connectorTagName="div"
      @outletArgs={{hash category=@category tag=@tag}}
    />
  {{/if}}
</section>