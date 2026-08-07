class CreateEventVotes < ActiveRecord::Migration[7.2]
  def change
    create_table :event_votes do |t|
      t.references :event, null: false, foreign_key: true
      t.string :user_id, null: false
      t.string :vote_type, null: false

      t.timestamps
    end

    add_index :event_votes, [ :event_id, :user_id ], unique: true
    add_index :event_votes, :user_id
  end
end
