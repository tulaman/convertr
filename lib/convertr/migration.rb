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
        t.datetime :src_deleted_at
        t.datetime :convertor_deleted_at
      end

      create_table :tasks do |t|
        t.integer :file_id
        t.integer :bitrate
        t.string :convert_status, :limit => 20
        t.datetime :convert_started_at
        t.datetime :convert_stopped_at
        t.string :copy_status, :limit => 20
        t.datetime :copy_started_at
        t.datetime :copy_stopped_at
        t.boolean :crop
        t.boolean :deinterlace
      end
    end

    def self.down
      drop_table :tasks
      drop_table :files
    end
  end
end
