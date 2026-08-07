class CreateEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :events do |t|
      t.string :billetto_id, null: false
      t.string :name
      t.string :state
      t.string :kind
      t.boolean :public
      t.boolean :online_event
      t.jsonb :raw_payload, null: false, default: {}

      t.timestamps
    end

    add_index :events, :billetto_id, unique: true
    add_index :events, :state
  end
end
