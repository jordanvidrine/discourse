import Component from "@ember/component";

export default class ReviewablePostHeader extends Component {}

<div class="reviewable-post-header">
  <ReviewableCreatedByName @user={{this.createdBy}} />
  {{#if this.reviewable.reply_to_post_number}}
    <a
      href={{concat
        this.reviewable.topic_url
        "/"
        this.reviewable.reply_to_post_number
      }}
      class="reviewable-reply-to"
    >
      {{d-icon "share"}}
      <span>{{i18n "review.in_reply_to"}}</span>
    </a>
  {{/if}}
</div>