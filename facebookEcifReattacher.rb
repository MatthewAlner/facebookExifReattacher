#!/usr/bin/env ruby
require'mini_exiftool'
require 'optparse'

$DEBUG = false
$DRY_RUN = false
$PATH = ""

def parse_options()
    options = {}

    optparse = OptionParser.new do |opts|
        opts.banner = "Usage: facebookEcifReattacher.rb [options]"

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
            options[:verbose] = v
        end

        opts.on("-d", "--[no-]dry_run", "Show files that will be effected but don't do anything") do |d|
            options[:dry_run] = d
        end

        opts.on("-p", "--path=PATH", "Path of the facebook photo folder") do |path|
            options[:path] = path
        end

        opts.on("-h", "--help", "Prints this help") do
            puts opts
            exit
        end

    end

    optparse.parse!

    if !options[:verbose].nil? then $DEBUG = options[:verbose] end
    if !options[:dry_run].nil? then $DRY_RUN = options[:dry_run] end
    if !options[:path].nil? then $PATH = options[:path] end

    if($DEBUG)
        puts "Verbose: " + $DEBUG.to_s
        puts "Dry run: " + $DRY_RUN.to_s
        puts "Path: " + $PATH.to_s
    end

    check_for_missing_options(optparse, options)
end

def check_for_missing_options(optparse, options)
    begin
        mandatory = [:path]
        missing = mandatory.select{ |param| options[param].nil? }
        unless missing.empty?
          puts "Missing options: #{missing.join(', ')}"
            puts optparse
            exit
        end
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument
        puts $!.to_s
        puts optparse
        exit
    end
end

class Image
    attr_accessor :name
    attr_accessor :date_created
    attr_accessor :date_posted
    def initialize(name, date_created, date_posted)
        @name = name
        @date_created = date_created
        @date_posted = date_posted
    end
end

def read_file(file_name)
    file = File.open(file_name, "r")
    data = file.read
    file.close
    return data
end

def get_exif_data_from_folders_index_file(folder_path)

    index_file_contents = read_file(folder_path + '/index.htm')
    regex = /photos\/\d+\/(\d+).jpg(?:.+?)<div class="meta">(.+?)<\/div>(<table class="meta">(?:.+?)<\/table>)?/
    images_exif_data = []

    index_file_contents.scan(regex) do |name, date_posted, exifTable|
        name = name + ".jpg"
        date_posted = DateTime.parse(date_posted)
        if exifTable.is_a? String
            date_created_unix_string = get_exif_out_of_table(exifTable)
            if !date_created_unix_string.empty? then
                date_created = Time.at(date_created_unix_string.to_i).to_datetime
            end
        else
            imgToStore = false
        end
        if $DEBUG
            puts "name: \t\t" + name
            puts "date_posted: \t" + date_posted.to_s
            puts "date_created: \t" + date_created.to_s
            puts "\n"
        end

        imgToStore = Image.new(name, date_created, date_posted)
        images_exif_data.push(imgToStore)
    end
        images_exif_data
end

def get_exif_out_of_table(table)
    regex = /<th>(.*?)<\/th><td>(.*?)<\/td>/
    date_created = ""
    table.scan(regex) do |key, value|
        if key == "Taken" then
            date_created = value
        end
    end
    date_created
end

def get_images_from_folder(folder_path)
    root_folder = File.absolute_path(folder_path)
    image_files = Dir["#{root_folder}/*.jpg"]
    images_names_only = []
    image_files.each do |file|
        file_name = File.absolute_path(file).gsub("#{root_folder}/","")
        if $DEBUG
            puts "found in folder: #{file_name}"
        end
        images_names_only.push(file_name)
    end
    images_names_only
end

def update_images_with_correct_exif_data(images_exif_data, images_names_only, folder_path)
    images_names_only.each do |image_name|
        images_exif_data.each do |image_data|
            if image_name == image_data.name
                if !$DRY_RUN
                    modify_images_created_date(image_name, image_data, folder_path)
                end
            end
        end
    end
end

def modify_images_created_date(image_name, image_data, folder_path)
    if image_data.date_created
        new_time = image_data.date_created.strftime("%Y:%m:%d %T")
        image_to_update = MiniExiftool.new(folder_path + "/" + image_name)
        image_to_update.date_time_original = new_time
        image_to_update.save
        puts "updated: #{image_name} \t > using CREATED date \t > #{new_time}"
    else
        new_time = image_data.date_posted.strftime("%Y:%m:%d %T")
        image_to_update = MiniExiftool.new(folder_path + "/" + image_name)
        image_to_update.date_time_original = new_time
        image_to_update.save
        puts "updated: #{image_name} \t > using POSTED date \t > #{new_time}"
    end
end

def process_folder(folder_path)
    puts "processing folder: #{folder_path}"
    images_exif_data = get_exif_data_from_folders_index_file(folder_path)
    images_names_only = get_images_from_folder(folder_path)
    update_images_with_correct_exif_data(images_exif_data, images_names_only, folder_path)
end

def process_facebok_data_dump(path)
    all_image_folders = Dir.glob(path + '/*').select {|f| File.directory? f}

    all_image_folders.each do |folder|
        process_folder(folder)
    end
end

parse_options
process_facebok_data_dump($PATH)

###TODO###
# Need to add progress and counters
# Need keep and print list of non updated images
# Final count of createdDate vs Posted vs Not updated
# option to copy or move to another folder
# captue more of the exif data
# update files created date as well as the exif data
# renaming files with date stamp
# renaming files back to orig name or facebook name
