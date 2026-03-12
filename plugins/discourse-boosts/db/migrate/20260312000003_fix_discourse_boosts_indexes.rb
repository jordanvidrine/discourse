# frozen_string_literal: true

class FixDiscourseBoostsIndexes < ActiveRecord::Migration[7.2]
  def change
    remove_index :discourse_boosts, :post_id
    remove_index :discourse_boosts, :user_id
  end
end
