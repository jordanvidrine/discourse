# frozen_string_literal: true

module DiscourseBoosts
  class BoostSerializer < ::ApplicationSerializer
    attributes :id, :cooked, :can_delete

    has_one :user, serializer: ::BasicUserSerializer, embed: :objects

    def can_delete
      scope.user && (object.user_id == scope.user.id || scope.can_review_topic?(object.post.topic))
    end
  end
end
