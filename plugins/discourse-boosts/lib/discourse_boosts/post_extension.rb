# frozen_string_literal: true

module DiscourseBoosts
  module PostExtension
    def self.prepended(base)
      base.has_many :boosts,
                    -> { order(:created_at) },
                    class_name: "DiscourseBoosts::Boost",
                    dependent: :delete_all
    end
  end
end
