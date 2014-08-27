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

set :environment, :development
set :bind, '0.0.0.0'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper::setup( :default, "sqlite3://#{Dir.pwd}/inv.db" )
DataMapper::Model.raise_on_save_failure = true  # globally across all models

class Device
  include DataMapper::Resource
  property :id,               Serial
  property :upca,             String
  property :imei,             String
  property :iccid,            String
  property :serial,           String,  required: true, key: true
  property :modelid,          String
  property :ats_warehouse,    String,  default: 'Unassigned'
  property :status,           String,  default: 'Unassigned'
  property :created_at,       DateTime
  # belongs_to :person
  # belongs_to :shipment
end

# class Person
#   include DataMapper::Resource
#   property :id, Serial
#   property :full_name,    String
#   property :company,    String
#   property :address_1,    String
#   property :address_2,    String
#   property :city,    String
#   property :region,    String
#   property :country,    String
#   property :postalcode,    String
#   # has n, :device
# end

# class Shipment
#   include DataMapper::Resource
#   property :id, Serial
#   property :shipment_method,    String
#   property :shipment_tracking,    String
#   property :shipped,    Boolean
#   property :created_at, DateTime
#   belongs_to :device

# end


DataMapper.auto_upgrade!
DataMapper.finalize


get '/chart' do

  Chartkick.options = {
    height: "200px",
    colors: ["red", "#999"]
  }
  Chartkick.options[:html] = '<div id="%{id}" style="height: %{height};">Loading...</div>'

  @devices = Device.all(id: 4..6, fields: [:id,:serial,:ats_warehouse,:status])

  haml :chart
end


get '/' do

 @title = 'Available Devices'
 @devices = Device.all
 haml :list
end

get '/new' do
  haml :form
end

get '/device' do
  @title = 'Available Devices'
  @devices = Device.all
  haml :list
end

get '/device/json' do

  @devices = Device.all
  content_type :json
  @devices.to_json
end

get '/device/csv' do

  @devices = Device.all
  content_type 'application/csv'
  @stamp = Time.now.strftime("%Y%m%d")
  attachment "#{@stamp}_export.csv"
  @devices.to_csv
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

get '/device/upca/:upca' do
  @title = 'UPCA FILTER'
  @upca = params[:upca]
  @devices = Device.all(upca: @upca)
  haml :list
end

get '/device/iccid/:iccid' do
  @title = 'ICCID FILTER'
  @iccid = params[:iccid]
  @devices = Device.all(iccid: @iccid)
  haml :list
end

get '/device/imei/:imei' do
  @title = 'IMEI FILTER'
  @imei = params[:imei]
  @devices = Device.all(imei: @imei)
  haml :list
end

get '/device/location/:location' do
  @title = 'LOCATION FILTER'
  @location = params[:location]
  @devices = Device.all(ats_warehouse: @location)
  haml :list
end

get '/device/status/:status' do
  @title = 'STATUS FILTER'
  @status = params[:status]
  @devices = Device.all(status: @status)
  haml :list
end


get '/device/modelid/:modelid' do
  @title = 'MODEL FILTER'
  @modelid = params[:modelid]
  @devices = Device.all(modelid: @modelid)
  haml :list
end

get '/device/serial/:serial' do
  @title = 'Serial Number Filter'
  @serial = params[:serial]
  @devices = Device.last(serial: @serial)
  haml :single
end

get '/device/id/:id' do
  @title = 'Change View'
  @id = params[:id]
  @devices = Device.last(id: @id)
  haml :change
end

get '/edit/device/id/:id' do
  @title = 'Edit View'
  @id = params[:id]
  @devices = Device.last(id: @id)
  haml :edit_form
end

post '/edit/device' do
  @id = params[:id]
  @serial = params[:serial]
  Device.get(@id,@serial).update(params[:device])
  redirect to('/')
end


get '/delete/id/:id' do
  @id = params[:id]
  @devices = Device.last(id: @id)
  haml :delete
end
get '/delete/id/confirmed/:id' do
  @id = params[:id]
  @todelete = Device.last(id: @id)
  @todelete.destroy
  redirect to('/')
end
