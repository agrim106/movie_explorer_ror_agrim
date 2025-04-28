class CreateMovies < ActiveRecord::Migration[7.1]
  def change
    create_table :movies do |t|
      t.string :title
      t.string :genre
      t.integer :release_year
      t.float :rating, default: 0.0
      t.string :director
      t.integer :duration
      t.string :streaming_platform
      t.string :main_lead
      t.text :description
      t.boolean :premium, default: false, null: false

      t.timestamps
    end
    add_index :movies, :title
    add_index :movies, :release_year
  end
end