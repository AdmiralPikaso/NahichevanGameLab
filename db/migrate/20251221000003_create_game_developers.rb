class CreateGameDevelopers < ActiveRecord::Migration[7.0]
  def change
    create_table :game_developers do |t|
      t.references :game, foreign_key: true       
      t.references :developer, foreign_key: true  
      
      t.timestamps
    end
    
    
    add_index :game_developers, [:game_id, :developer_id], unique: true
  end
end