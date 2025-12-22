class CreateRatings < ActiveRecord::Migration[7.0]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.integer :score, null: false
      t.timestamps
    end
    
    # Одна оценка от пользователя на игру
    add_index :ratings, [:user_id, :game_id], unique: true
  end
end