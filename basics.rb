require 'haml'
require 'dm-core'
require 'dm-sqlite-adapter'
require 'dm-migrations'
require 'sinatra'
require 'sinatra/reloader'
require "dm-noisy-failures"

set :environment, :development
set :bind, '0.0.0.0'


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

get '/' do

 @title = 'Available Devices'
 @devices = Device.all
 haml :list

end

get '/new' do

  haml :form

end


post '/device' do
  Device.create params[:device]
  redirect to('/')
end

get '/device' do
  @title = 'Available Devices'
  @devices = Device.all
  haml :list

end

get '/device/:serial' do

  @devices = Device.get(serial: params[:serial])
  haml :list

end

