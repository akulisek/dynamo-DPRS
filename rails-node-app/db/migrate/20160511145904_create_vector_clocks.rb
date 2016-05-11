class CreateVectorClocks < ActiveRecord::Migration
  def change
    create_table :vector_clocks do |t|

      t.timestamps null: false
    end
  end
end
