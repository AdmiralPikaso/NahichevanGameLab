class AddNotesToWishlists < ActiveRecord::Migration[8.1]
  def change
    add_column :wishlists, :notes, :text
    add_column :wishlists, :priority, :integer
  end
end
