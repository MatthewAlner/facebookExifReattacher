# facebookExifReattacher
## What this does
When you download a copy of all your facebook data though facebooks "Download a copy" feature you get all your photos but they have no exif data and there date created is the date of download.

The exif data can however be found in the index.htm files accompanying the photos.

This Ruby script scrapes the index.htm files and updates the downloaded photos "date/time original" with the taken date. If there is no available taken date it sets the "date/time original" as the date it was posted to Facebook instead.

## What you will need

* ExifTool
  * http://www.sno.phy.queensu.ca/~phil/exiftool/
* A copy of your Facebook data
  * https://www.facebook.com/help/131112897028467/
* This ruby script

## Usage

$ facebookExifReattacher.rb [options]

| Short | Long           | Description
| ------|--------------- | --------------------
| -v    | --[no-]verbose | Run verbosely
| -d    | --[no-]dry_run | Show files that will be effected but don't do anything
| -p    | --path=PATH    | Path of the facebook photo folder
| -h    | --help         | Prints help
