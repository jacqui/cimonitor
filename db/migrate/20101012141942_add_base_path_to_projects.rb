class AddBasePathToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :base_path, :string
  end

  def self.down
    remove_column :projects, :base_path
  end
end
