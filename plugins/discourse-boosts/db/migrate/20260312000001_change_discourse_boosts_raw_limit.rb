# frozen_string_literal: true

class ChangeDiscourseBoostsRawLimit < ActiveRecord::Migration[7.2]
  def up
    change_column :discourse_boosts, :raw, :string, limit: 1000, null: false
  end

  def down
    change_column :discourse_boosts, :raw, :string, limit: 16, null: false
  end
end
