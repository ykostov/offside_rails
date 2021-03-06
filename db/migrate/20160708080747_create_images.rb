class CreateImages < ActiveRecord::Migration[4.2]
  def change
    create_table :images do |t|
      t.string :name
      t.string :picture_id
      t.references :article, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.string :tag

      t.timestamps null: false
    end
  end
end
