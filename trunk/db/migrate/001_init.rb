class Init < ActiveRecord::Migration
  def self.up
    f = File.new('db/init_schema.sql')
    execute f.read
    f.close
  end

  def self.down
	
  end
end
