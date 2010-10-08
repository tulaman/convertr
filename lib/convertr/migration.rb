module Convertr
  class Migration < ActiveRecord::Migration
    def self.up
      create_table :files do |t|
        t.string :filename
        t.string :location
        t.datetime :enqueue_at
        t.string :convertor
        t.datetime :broadcast_at
        t.integer :src_size
        t.integer :duration
        t.string :aspect, :limit => 10
        t.integer :width
        t.integer :height
        t.boolean :src_deleted
        t.boolean :convertor_deleted
      end

      create_table :tasks do |t|
        t.integer :file_id
        t.integer :bitrate
        t.string :convert_status, :limit => 20
        t.boolean :convert_started
        t.boolean :convert_stopped
        t.string :copy_status, :limit => 20
        t.boolean :copy_started
        t.boolean :copy_stopped
        t.boolean :crop
        t.boolean :deinterlace
      end
    end

    def self.down
      drop_table :task
      drop_table :file
    end
  end
end
