class AddVoteCountsToEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :events, :upvotes_count, :integer, null: false, default: 0
    add_column :events, :downvotes_count, :integer, null: false, default: 0
  end
end
