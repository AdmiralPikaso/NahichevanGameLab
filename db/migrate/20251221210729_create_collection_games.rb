class CreateCollectionGames < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_games do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true

      t.timestamps
    end
  end
end
