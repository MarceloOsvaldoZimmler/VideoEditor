3.2.14 -> 3.2.15
----------------
* mashes with image clips that require padding (because their length is not at least
double adjacent transitions) must be resaved in editor or have their lengths/starts
adjusted manually before rendering.


3.2.11 -> 3.2.14
----------------
* transcode example now expects clip tags of type mash to put the URL to the render mash
in the 'source' attribute, rather than 'url'. The 'url' attribute is now the place to put
the URL that returns the actual mash tag. The mash tag now fully supports the 'config'
attribute within the apple and transcoder.
* PercentPartial Output variable changed to PercentEstimate (still in PercentDone though)
* The IBuffered interface has switched over to using the new Time and TimeRange objects, 
for proper timing calculations. Affected subclasses include IClip, IMash and IModule. 
* Change best value of Quality element to 1 instead 100, to match qscale:v value
* Still untested: transcoding of custom modules/fonts, image/sequence output from input 
other than raw assets, trimming of image/sequence output, embedded mashes having different
quantize properties.

3.2.10 -> 3.2.11
----------------
* PercentDone tag deprecated in REST GET responses - use Percent or PercentPartial instead
* In jobs with sequence Output the Percent tag might contain zero, indicating the 
Transcoder can't determine the number of frames in the sequence until the duration of the 
input is determined. In these cases the PercentPartial and PercentDone tags will contain a
number that's likely to be much higher than Percent and PercentDone will be once the frame 
count is known. The approached used in the updated 'transcode' is to report back to the 
applet just 25% of PercentPartial if Percent is zero. 

3.1.XX -> 3.2.XX
----------------
* Transcoding functionality moved from distribution to new Movie Masher Transcoder AMI
* 'server' example now known as 'transcode' - updated to work with new Transcoder API
* Configuration file private/MovieMasher.xml replaced by moviemasher.ini
* Only 'REST' or 'SQS' now supported for Client configuration option
* Only 'HTTP' or 'Local' now supported for File configuration option (S3 provided by HTTP)
* Player and Browser controls need to have id specifically set
* Player now requires 'source' attribute - probably 'mash'
* Example index pages now require video_width and video_height keys for flashvarsObj object
* CGI 'mash' attribute should now be 'player.mash' or other mash object
* Bender control tag 'shader' attribute changed to 'source' 
* Moved bender .pbj files to moviemasher/com/moviemasher/pbj
* The following classes have been migrated to the Player SWF file:
	com.moviemasher.handler.MP3Handler
	com.moviemasher.source.RemoteSource
	com.moviemasher.display.Tooltip
* The following classes have been migrated to the Editor SWF file:
	com.moviemasher.display.Increment
* 'tie' control attribute removed - use full references in 'pattern' instead, or just 
remove since controls like Scrollbar, Ruler, Timeline no longer need them
* Flash CS5.5 now required to rebuild FLA files
* Previews use over* attributes instead of sel* for selected box properties 
* Curve library item removed from library in skin file - use the following instead:
	color='333333' grad='40' angle='270' curve='5'
* Tooltip class variable on frame one of custom skin SWFs should be removed, if found
* Increment library symbol in skin SWF should be removed
* Fullscreen icons moved from library to timeline in skin file