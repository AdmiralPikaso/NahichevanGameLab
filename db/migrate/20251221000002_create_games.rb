class CreateGames < ActiveRecord::Migration[7.0]
  def change
    create_table :games do |t|
      t.string :title           
      t.text :description      
      t.date :release_date     
      t.string :cover_url       
      t.integer :metacritic_score 
      
      t.timestamps
    end
    
    
    add_index :games, :title, unique: true
  end
end