class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.integer :rating, null: false
      t.timestamps
    end
    
    # Индекс для быстрого поиска рецензий пользователя
    add_index :reviews, [:user_id, :created_at]
  end
end