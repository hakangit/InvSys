require 'rubygems'
require 'bundler/setup'

# normal stuff
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
  property :iccid,            String,  default: '000000000000000000000'
  property :serial,           String,  key: true
  property :modelid,          String,  default: 'Unknown'
  property :accessory1,       String,  default: 'Unassigned'
  property :accessory2,       String,  default: 'Unassigned'
  property :location,         String,  default: 'Unassigned'
  property :status,           String,  default: 'Unassigned'
  property :firstname,        String,  default: 'Unassigned'
  property :lastname,         String,  default: 'Unassigned'
  property :created_at,       DateTime
end

DataMapper.finalize
DataMapper.auto_upgrade!


def decode(input)
  @input = input
  @data = Hash.new

  @input.each do |x|
    case x
      when /\A[\d]{12}\z/
        @data["upca"] = x
      when /\A[\d]{15}\z/
        @data["imei"] = x
      when /\A[\d]{20}\z/
        @data["iccid"] = x
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
  $stderr.puts "#{@pre}"
  @post = decode(@pre.values)
  $stderr.puts "#{@post}"
  Device.create @post
  redirect to('/')
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


