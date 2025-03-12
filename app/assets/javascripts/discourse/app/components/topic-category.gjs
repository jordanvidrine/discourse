import Component from "@ember/component";

// Injections don't occur without a class
export default class TopicCategory extends Component {}

{{#unless this.topic.isPrivateMessage}}
  {{bound-category-link
    this.topic.category
    ancestors=this.topic.category.predecessors
    hideParent=true
  }}
{{/unless}}
<div class="topic-header-extra">
  {{#if this.siteSettings.tagging_enabled}}
    <div class="list-tags">
      {{discourse-tags this.topic mode="list" tags=this.topic.tags}}
    </div>
  {{/if}}
  {{#if this.siteSettings.topic_featured_link_enabled}}
    {{topic-featured-link this.topic}}
  {{/if}}
</div>

<span>
  <PluginOutlet
    @name="topic-category"
    @connectorTagName="div"
    @outletArgs={{hash topic=this.topic category=this.topic.category}}
  />
</span>