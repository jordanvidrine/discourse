# frozen_string_literal: true

class AddUniqueIndexToDiscourseBoostsPostUser < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  INDEX_NAME = "index_discourse_boosts_on_post_id_and_user_id"

  def up
    execute <<~SQL
      DELETE FROM discourse_boosts
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM discourse_boosts
        GROUP BY post_id, user_id
      )
    SQL

    execute <<~SQL
      DROP INDEX CONCURRENTLY IF EXISTS "#{INDEX_NAME}"
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS "#{INDEX_NAME}"
      ON discourse_boosts (post_id, user_id)
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX CONCURRENTLY IF EXISTS "#{INDEX_NAME}"
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS "#{INDEX_NAME}"
      ON discourse_boosts (post_id, user_id)
    SQL
  end
end
