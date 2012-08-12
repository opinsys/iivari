class CreateDocsplitTasks < ActiveRecord::Migration
  def change
    create_table :docsplit_tasks do |t|
      t.belongs_to :channel
      t.string :document_file_path, :null => false
      t.string :original_file_name
      t.boolean :pending, :default => true, :index => true
      t.integer :progress, :default => 0
      t.boolean :resolved, :default => false
      t.boolean :rejected, :default => false
      t.text :error
      t.timestamps
    end
  end
end
