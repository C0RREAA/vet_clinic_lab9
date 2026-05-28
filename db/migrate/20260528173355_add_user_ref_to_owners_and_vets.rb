class AddUserRefToOwnersAndVets < ActiveRecord::Migration[8.1]
  def change
    add_reference :owners, :user, null: true, foreign_key: true
    add_reference :vets,   :user, null: true, foreign_key: true
  end
end
