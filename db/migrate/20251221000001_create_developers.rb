class CreateDevelopers < ActiveRecord::Migration[7.0]
  def change
    create_table :developers do |t|
      t.string :name            
      t.string :country         
      t.integer :founded_year   
      
      t.timestamps
    end
    
    add_index :developers, :name, unique: true
  end
end