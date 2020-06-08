### S3D Thumbnail Generator for PrusaThumbnail plugin on OctoPrint.

#### Linux only currently

1. Download and place the script on your system somewhere with permissions allowing S3D to access.
   `git clone https://github.com/NotExpectedYet/s3d-thumbnail-generator.git`

2. Edit the thumbnailGeneration.bash file with your working directory. (/tmp will work fine I just left mine in my user folder).
   `WORKINGDIR="<Your full system path here>"`

3. You will need to figure out where to crop on your screen size. If your resolution is 1920x1080 then it should already work fine with the default settings. You'll have to play with these to figure out the best settings for your resolution otherwise.
   `-crop 1583x792+285+32`

4. Make sure to install xdotools and imagemagik(usually on your OS)
   `sudo apt-get install xdotool`
   `sudo apt install imagemagick`

5. Open S3D and input the location of your script into the post-processing tab.
   ![S3D Settings screentshot](s3dsettings.png "S3D Settings")

6. Slice something and await the script to run. It currently adds 2 seconds onto the slice completion time as I found the script was a little too fast at generating the thumbnail. You can change this
   `PAUSE="2"`

7. Upload to your OctoPrint instance that has the PrusaThumbnail plugin installed.
   `https://plugins.octoprint.org/plugins/prusaslicerthumbnails/`

8. Profit!
   ![OctoFarm working with the plugin](profitScreenshot.jpg "OctoFarm working with the plugin")

#### Notes: I feel this works ok, although I'd rather generate the thumbnail with openSCAD currently S3D stops that due to having no [input_filename] variable like it does for the [output_filename]. I have noticed however some beneficts to having the gcode preview displayed rather than the actual model. For one, I know where my supports were but that will be user dependant and I do agree it would be nicer with a clean thumbnail similar to prusa/cura.
