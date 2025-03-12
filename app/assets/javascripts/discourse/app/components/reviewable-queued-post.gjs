import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import RawEmailModal from "discourse/components/modal/raw-email";

export default class ReviewableQueuedPost extends Component {
  @service modal;

  @tracked isCollapsed = false;
  @tracked isLongPost = false;
  @tracked postBodyHeight = 0;
  maxPostHeight = 300;

  @action
  showRawEmail(event) {
    event?.preventDefault();
    this.modal.show(RawEmailModal, {
      model: {
        rawEmail: this.args.reviewable.payload.raw_email,
      },
    });
  }

  @action
  toggleContent() {
    this.isCollapsed = !this.isCollapsed;
  }

  get collapseButtonProps() {
    if (this.isCollapsed) {
      return {
        label: "review.show_more",
        icon: "chevron-down",
      };
    }
    return {
      label: "review.show_less",
      icon: "chevron-up",
    };
  }

  @action
  setPostBodyHeight(offsetHeight) {
    this.postBodyHeight = offsetHeight;

    if (this.postBodyHeight > this.maxPostHeight) {
      this.isCollapsed = true;
      this.isLongPost = true;
    } else {
      this.isCollapsed = false;
      this.isLongPost = false;
    }
  }
}

<ReviewableTopicLink @reviewable={{@reviewable}} @tagName="">
  <div class="title-text">
    {{d-icon "square-plus" title="review.new_topic"}}
    {{@reviewable.payload.title}}
  </div>
  {{category-badge @reviewable.category}}
  <ReviewableTags @tags={{@reviewable.payload.tags}} @tagName="" />
  {{#if @reviewable.payload.via_email}}
    <a href {{on "click" this.showRawEmail}} class="show-raw-email">
      {{d-icon "envelope" title="post.via_email"}}
    </a>
  {{/if}}
</ReviewableTopicLink>

<div class="post-contents-wrapper">
  <ReviewableCreatedBy @user={{@reviewable.target_created_by}} />

  <div class="post-contents">
    <ReviewablePostHeader
      @reviewable={{@reviewable}}
      @createdBy={{@reviewable.target_created_by}}
      @tagName=""
    />

    <CookText
      class="post-body {{if this.isCollapsed 'is-collapsed'}}"
      @rawText={{@reviewable.payload.raw}}
      @categoryId={{@reviewable.category_id}}
      @topicId={{@reviewable.topic_id}}
      @paintOneboxes={{true}}
      @opts={{hash removeMissing=true}}
      @onOffsetHeightCalculated={{this.setPostBodyHeight}}
    />

    {{#if this.isLongPost}}
      <DButton
        @action={{this.toggleContent}}
        @label={{this.collapseButtonProps.label}}
        @icon={{this.collapseButtonProps.icon}}
        class="btn-default btn-icon post-body__toggle-btn"
      />
    {{/if}}

    {{yield}}
  </div>
</div>