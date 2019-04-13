require 'yaml'
require 'nexpose'
require 'optparse'
include Nexpose
require 'text-table'

table = Text::Table.new
table.head = ['ACTION','DATE TIME','ID', 'IP','Operating System']
config_path = File.expand_path("/home/nexpose/ruby/conf/nexpose.yaml", __FILE__)
config = YAML.load_file(config_path)
cleanup_time = 90
@host = config["hostname"]
@userid = config["username"]
@password = config["passwordkey"]
@port = config["port"]

nsc = Nexpose::Connection.new(@host, @userid, @password, @port)
day_of_run = Time.now.strftime("%m/%d/%Y")
puts "-"*50
puts "#{Time.now.strftime("%m/%d/%Y %H:%M:%S")}\tInitiating Nexpose Clean Asset Purge (#{cleanup_time} Days)"
puts "#{Time.now.strftime("%m/%d/%Y %H:%M:%S")}\tLogging into Nexpose"

begin
    nsc.login
    rescue ::Nexpose::APIError => err
    $stderr.puts("#{Time.now.strftime("%m/%d/%Y %H:%M:%S")}\tConnection failed: #{err.reason}")
    exit(1)
end

puts "#{Time.now.strftime("%m/%d/%Y %H:%M:%S")}\tSuccessfully Logged into Nexpose"
at_exit { nsc.logout }
        ignore_assets = Nexpose::AssetGroup.load(nsc, 31).devices.each do |device|
        asset_info = Nexpose::Asset.load(nsc,device.id)
end

old_assets = nsc.filter(Search::Field::SCAN_DATE, Search::Operator::EARLIER_THAN, cleanup_time)
puts "#{Time.now.strftime("%m/%d/%Y %H:%M:%S")}\tAssets to be deleted:\t#{old_assets.count}"
puts "#{Time.now.strftime("%m/%d/%Y %H:%M:%S")}\tAssets to be Ignored:\t#{ignore_assets.count}"
old_assets.each do |asset|
        next if ignore_assets.map(&:id).include?(asset.id)
        deleted_asset_info  = Nexpose::Asset.load(nsc,asset.id)
        table.rows << ["DELETED","#{Time.now.strftime("%m/%d/%Y %H:%M:%S")}", asset.id,deleted_asset_info.ip,deleted_asset_info.os_name]
        #nsc.delete_asset(asset.id)
end
table.to_s
puts table
puts "#{Time.now.strftime("%m/%d/%Y %H:%M:%S")}\tProccess Completed"
