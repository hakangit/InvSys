require 'dm-core'
require 'dm-sqlite-adapter'
require 'dm-migrations'
require 'dm-serializer'
require 'dm-noisy-failures'
require 'json'
require 'haml'
require 'chartkick'
require 'sinatra'
require 'sinatra/reloader'
require 'logger'

set :environment, :development
set :logging, :true
set :bind, '0.0.0.0'

DataMapper::Logger.new(STDOUT, :info)
DataMapper::setup( :default, "sqlite3://#{Dir.pwd}/dev.db" )
# DataMapper::Model.raise_on_save_failure = true  # globally across all models

  configure :production do
    Dir.mkdir('logs') unless File.exist?('logs')
       $logger = Logger.new('logs/common.log','weekly')
       $logger.level = Logger::WARN

       # Spit stdout and stderr to a file during production
       # in case something goes wrong
       $stdout.reopen("logs/output.log", "w")
       $stdout.sync = true
       $stderr.reopen($stdout)
  end

  configure :development do
    $logger = Logger.new(STDOUT)
    $logger.level = Logger::INFO
  end

class Device
  include DataMapper::Resource
  property :upca,             String
  property :imei,             String
  property :iccid,            String
  property :serial,           String,  key: true
  property :modelid,          String
  property :ats_id,           String
  property :location,         String,  default: 'Unassigned'
  property :status,           String,  default: 'Unassigned'
  property :carrier_part,     String
  property :carrier_part_2,   String
  property :created_at,       DateTime
  has 1, :sim
end

class Sim
  include DataMapper::Resource
  property :id,               Serial
  property :upca,             String,  default: 'None'
  property :sku,              String,  default: 'None'
  property :iccid,            String,  default: 'None'
  property :ats_warehouse,    String,  default: 'Unassigned'
  property :status,           String,  default: 'Unassigned'
  property :created_at,       DateTime
  has 1, :device

end

# class Shipment
#   include DataMapper::Resource
#   property :id,                   Serial
#   property :courier,              String
#   property :tracking_number,      String
#   property :status,               String
#   property :shipped,              Boolean
#   property :created_at,           DateTime
#   property :src_name,             String
#   property :src_address_1,        String, default: ''
#   property :src_address_2,        String, default: ''
#   property :src_city,             String, default: ''
#   property :src_region,           String, default: ''
#   property :src_country,          String, default: ''
#   property :src_postalcode,       String, default: ''
#   property :dst_name,             String
#   property :dst_address_1,        String, default: ''
#   property :dst_address_2,        String, default: ''
#   property :dst_city,             String, default: ''
#   property :dst_region,           String, default: ''
#   property :dst_country,          String, default: ''
#   property :dst_postalcode,       String, default: ''
#   has 0..n, :place
#   has n, :device
# end


DataMapper.finalize
DataMapper.auto_upgrade!


def decode(input)
  @input = input
  @data = Hash.new

  @input.each do |x|
    case x
      when /\A[\d]{7}\z/
        @data["ats_id"] = x
      when /\A[\d]{12}\z/
        @data["upca"] = x
      when /\A[\d]{15}\z/
        @data["imei"] = x
      when /\A[\d]{5}\z/
        @data["carrier_part"] = x
      when /\A[\d]{20}\z/
        @data["iccid"] = x
      when /\A1P\d.*/
        @data["carrier_part_2"] = x
      when /\A1P\w{2}\d{3}\w{2}[\/\d]\w\z/
        @data["modelid"] = x[2..-1]
      when /\AS\w{12}\z/
        @data["serial"] = x
    end
  end
  return @data
end



get '/chart' do
  Chartkick.options = {
    height: "200px",
    colors: ["red", "#999"]
  }
  Chartkick.options[:html] = '<div id="%{id}" style="height: %{height};">Loading...</div>'

  @devices = Device.all(fields: [:serial,:location,:status])

  haml :chart
end


get '/' do

 @title = 'Available Devices'
 @devices = Device.all
 @sims = Sim.all
 haml :list
end

get '/new' do
  haml :form
end

get '/barnew' do
  haml :bar_form
end

post '/device/barnew' do
  @pre = params[:device]
  @post = decode(@pre.values)
  $stderr.puts "#{@post}"
  @temp = Device.new @post
  @temp.sim = Sim.first_or_create({device_serial: @temp[:serial]})
  @temp.attributes = ({sim_id: @temp.sim[:id]})
  @temp.save
  redirect to('/barnew')
end

post '/device' do
  Device.create params[:device]
  redirect to('/')
end

post '/search' do
  @search = params[:search]
  @devices = Device.get(@search)
  haml :single
end

def json2csv(object)
  @header = true
  csv_string = CSV.generate do |csv|
    JSON.parse(object).each do |hash|
      if @header
        csv << hash.keys
      end
      @header = false
      csv << hash.values
      # csv << " #{data},"
    end
  end
  return csv_string
end

get '/device/csv' do
  content_type 'application/csv'
  attachment "devices.csv"
  json2csv(Device.all.to_json)
end

get '/sim/csv' do
  content_type 'application/csv'
  attachment "sims.csv"
  json2csv(Sim.all.to_json)
end

get '/device/list/serial/:serial' do
  @title = 'Record Information'
  @serial = params[:serial]
  @devices = JSON.parse(Device.last(serial: @serial).to_json)
  haml :single
end

get '/device/list/:property/:id' do
  @property = params[:property]
  @id = params[:id]
  @title = "#{@property.upcase} Filter"
  @type = Hash.new
  @type["#{@property}"] = "#{@id}"
  @devices = Device.all(@type)
  haml :list
end

get '/device/:serial' do
  @title = 'Change View'
  @serial = params[:serial]

  @devices = JSON.parse(Device.last(serial: @serial).to_json)
  haml :change
end

get '/device/:serial/edit' do
  @title = 'Edit View'
  @serial = params[:serial]
  @devices = Device.last(serial: @serial)
  haml :edit_form
end

post '/device/edit' do
  @serial = params[:serial]
  Device.get(@serial).update(params[:device])
  redirect to('/')
end

get '/delete/:serial' do
  @serial = params[:serial]
  @devices = Device.last(serial: @serial)
  haml :delete
end
get '/delete/confirmed/:serial' do
  @serial = params[:serial]
  @todelete = Device.last(serial: @serial)
  @todelete.destroy
  redirect to('/')
end

get '/device/sim_id/:id' do
  @title = 'Change View'
  @title = 'Record Information'
  @id = params[:id]
  @devices = JSON.parse(Sim.last(id: @id).to_json)
  haml :change_sim
end

get '/sim/:id/edit' do
  @title = 'Edit View'
  @id = params[:id]
  @devices = Sim.last(id: @id)
  haml :edit_form_sim
end

post '/sim/edit' do
  @id = params[:id]
  Sim.get(@id).update(params[:device])
  redirect to('/')
end


