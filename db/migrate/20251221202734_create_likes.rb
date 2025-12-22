class CreateLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :likes do |t|
      t.references :review, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    
    add_index :likes, [:review_id, :user_id], unique: true
  end
end