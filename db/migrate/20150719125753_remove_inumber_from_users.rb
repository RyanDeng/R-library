class RemoveInumberFromUsers < ActiveRecord::Migration
  def change
  	change_table :users do |t|
	  t.remove :i_number, :sf_email, :building, :seat
	end
  end
end
