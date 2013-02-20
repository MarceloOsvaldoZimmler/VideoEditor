Version 3.2.17
--------------
* Improved transcoding performance during rendering

Version 3.2.16
--------------
* Fixed issue keeping applet from loading mashes with no visual content
* Fixed issue with playback of muted audio Clips

Version 3.2.15
--------------
* Added call from applet to javascript:moviemasher() if 'evaluate' set in FlashVars
* Added IgnoreCache option for Input tags in Transcoder API to force asset reloading
* Added JavaScriptSource class for supplying media to applet from JavaScript
* Expanded API documentation on moviemasher.com to include all options and examples
* Expanded 'javascript' example to include setting of initial configuration
* Fixed export_init.php so that DecoderVideoBitrate setting in moviemasher.ini honored
* Fixed issue loading custom modules, fonts and PBJ files from transcoder
* Fixed issue keeping items from being dragged around within Browser control
* Fixed issue transcoding mash audio if tag had no 'audio' and 'volume' attributes
* Fixed issue with short image clips next to transitions (see Migration notes)

Version 3.2.14
--------------
* Added ability to sequence, trim and render multiple mashes and raw assets into one video
* Added support for Trim and Length elements within Transcoder Input and Output tags
* Added ability to parse options and parameters within all asset and data request URLs
* Added expression support on right side of hide, select and disable control attributes
* Added support for 'drop' tags within mash tag to indicate allowed media types
* Added support for 'config' attribute in Transcoder mash tags, to limit SQS message size
* Added support for 'source' attribute in MMComboBox control tags
* Added Delete button to Browser items in transcode example, and associated PHP script
* Added PercentDetail job variable with breakdown of tasks for custom progress reporting
* Added very alpha version of VoiceOver control to control_search.xml
* Added support for overriding of switch names in FFMpeg commands
* Added option to transcode example for mash icon generation on render, enabled by default
* Changed all timing methods within applet and Transcoder to avoid rounding issues 
* Changed Timeline drawing so clips display incrementally if there are many of them
* Changed Timeline so visual audio track only displays if mash has video containing audio
* Fixed (completely) issues on Transcoder AMI with Upstart boot sequence - thanks AWS!
* Fixed scaling issue causing mediocre module render quality in high resolution media
* Fixed pixel shift during rending when crop or pad worked out to an odd number of pixels 
* Fixed issue causing trim to change as speed was adjusted
* Fixed occasional icon placement problem in ButtonPreview
* Fixed audio hum introduced in renderings of mashes having incomplete audio
* Improved audio scrubbing during playback with no more stalling
* Improved duration accuracy for preprocessed audio files by using sox instead of ffmpeg
* Improved handling of CGI requests that fail to return a response, retried in most cases

Version 3.2.13
--------------
* Improved Transcoder progress and error callback feedback
* Added PathMovieMasher option to moviemasher.ini and mm_path FlashVar to all examples
* Fixed issues with freeze frame rendering wrong frame in some instances
* Fixed issues with audio drift during render in mashes with many short clips

Version 3.2.12
--------------
* Added support for multiple file uploads in CGI control and 'transcode' example
* Fixed (partially) issues on Transcoder with Upstart boot sequence
* Improved Transcoder render times for modular media by a factor between three and ten

Version 3.2.11
--------------
* Added Retries option for all Transfers types within Transcoder jobs
* Added Required option for all Output types within Transcoder jobs, including callbacks
* Added SQS safe shutdown routines during auto scaling of Transcoder instances
* Added support for updating applet parameters at runtime through JavaScript/ActionScript
* Added support for parsing of media tags as well as mash tags in evaluate() calls
* Changed range of volume on Transcoder from 0-100 to 0-200, so 50% indicates no change
* Changed default volume to 50% for audio and video throughout system
* Changed default evaluate/trigger delimiter to semicolon and updated examples
* Changed names of job related PHP scripts in 'transcode' example 
* Changed transcoder processing order so Job.Progress < 100 until other triggers transfer
* Fixed issues transcoding multiple mashes within same job request
* Fixed issues related to render and playback of audio-only mashes
* Fixed issue rendering mashes having no clips in main visual track
* Fixed apparent hang in 'transcode' example when job error encountered using SQS
* Fixed inappropriate durations in clips of type 'frame' during rendering
* Fixed transcode example moviemasher.ini to include -b (bitrate) switch for h264
* Fixed errant clip length in applet for video media of particular float durations
* Fixed issue with default zeropadding for videos near 10 and 100 seconds
* Fixed white on white text in longtext field control in panel.xml
* Fixed unescaped output issues in Transcoder callbacks
* Fixed issue with image and frame clips rendering at 25 FPS in all cases

Version 3.2.10
--------------
* Added support for mashes with no specified dimensions (uses Player dimensions)
* Fixed several issues keeping the Share example functioning properly
* Changed examples to use video_width and video_height applet parameters
* Changed 'transcode' example to draw video dimensions from moviemasher.ini
* Deprecated 'panels' tag - existing ones and their config attributes still respected

Version 3.2.09
--------------
* Fixed issues rendering very large videos having many effects, transitions
* Fixed issues allowing transitions to be placed consecutively
* Fixed issues displaying composite based transitions at mash start or end
* Fixed issues preventing custom fonts and modules from being rendered
* Fixed issues preventing certain tooltip values from evaluating
* Fixed 'transcode' example to support S3 regions other than US Standard
* Fixed font rendering issue when font had not been specifically set
* Fixed usage of deprecated loop_input FFMpeg switch 
* Added more sanity checks on 'transcode' example configuration
* Added selected and disabled states for control backgrounds (like previews)
* Changed example panel layout to take advantage of new options

Version 3.2.08
--------------
* Fixed rendering of scaled image clips using vector graphic media
* Fixed issue with absolute URL resolution in transcoder
* Added support for SQS queues in all AWS regions
* Removed ties between MovieMasher classes and 'server' example (now known as 'transcode')
* Changed XML structure of transcoding jobs extensively
* Added support for multiple transcoding job inputs, outputs and transfers
* Added generalized support for signing of file transfers during transcoding
* Removed S3 File transfer type and improved HTTP to support similar services
* Added support for auto recognition of audio-only video files on upload
* Added new 'mash' clip type for nesting of edit decision lists
* Added support for 'hide' attribute in ButtonPreview configuration
* Changed default render formatting to h264

Version 3.2.07
--------------
* Fixed rendering of transitioned instances of new frame clips
* Fixed various path issues in 'server' example 
* Added support for multiple files in File::HTTP without archiving

Version 3.2.06
--------------
* Added new 'frame' Clip type and Timeline function for single frame of video
* Added new PlayerFLV control for true video file playback
* Improved server logging and file transfer mechanisms
* Fixed rendering of scaled assets having different aspect ratios 
* Fixed issue rendering modules in mashes starting with a video clip

Version 3.2.05
--------------
* Added MIGRATION.txt document describing required updates to configuration 
* Added new Recorder control for media server interactions
* Added support for 'config' attribute in panels tag
* Added fullscreen support for panels and all their controls
* Optimized interface redrawing and image sequence loading
* Updated panel XML configuration to utilize styles and smart sizing

Version 3.2.04
--------------
* Added new Drawing effect module for stroked/filled ovals, rectangles and polygons
* Fixed errant meta tags in 'share' example that Facebook no longer supports
* Fixed issue causing just the first instance of ButtonPreview to display buttons

Version 3.2.03
--------------
* Fixed sound buffering issues for audio clips that loop
* Fixed issue in AVSequence when viewing a fraction of a frame beyond last frame
* Fixed audio timing issues for nested effects clips

Version 3.2.02
--------------
* Added new 'hide' attribute for panel and bar tags
* Added new 'loading' property to RemoteSource and progress indicator to panel.xml
* Added new ButtonPreview for buttons within Browser media items
* Added support for 'style' option tags to simplify panel, bar and control tags
* Added support for control tags having no 'symbol' attribute
* Added support for mathematical expressions in several sizing attributes
* Fixed issue preventing first frame of mash from being displayed
* Fixed Ruler and IIncrement classes to properly display longer timelines
* Fixed timing bug for effects nested in trimmed and timeshifted clips

Version 3.2.01
--------------
* Switched to direct sound buffering of MP3 soundtracks
* Removed support for unprocessed, raw video within editor
* Retired FLVHandler, AVVideo, YouTubeSource and YouTubeHandler classes

Version 3.1.13
--------------
* Fixed issue with resaving modules used as previews

Version 3.1.12
--------------
* Added Box, Grid, Ripple and Oval Crossfade transitions 
* Fixed issues with mashes ending in a transition
* Fixed issue with length calculation of newly dropped effect clips
* Fixed pid path for daemons so they can be properly terminated
* Fixed rendering of audio from additional composited clips

Version 3.1.11
--------------
* Added support for nested effects clips
* Added support for passthrough of arbitrary tags and attributes in mash XML
* Added 'noneditable' attribute to clip and media tags
* Added transformation properties to Chromakey effect
* Added support for frame graphics and control classes in same SWF
* Changed mash rendering mechanisms during playback and decoding
* Changed 'zeropadding' property to be optional
* Fixed curl calls to accommodate new AMI SSL version
* Fixed various issues with Picker control
* Fixed player.volume so it can be set in Player's control tag
* Fixed share example so it pulls in the player interface
* Fixed Browser control so clip data displays properly

Version 3.1.10
--------------
* Migrated Movie Masher Server to standard Amazon LINUX AMI

Version 3.1.09
--------------
* Attempted fix of EC2 AMI key copy issue

Version 3.1.08
--------------
* Fixed timeline track creation bug

Version 3.1.07
--------------
* Fixed timeline multi-selection issues
* Fixed cache managment functions that allowed it to fill up

Version 3.1.06
--------------
* Added support for read only clips - set editable='' in media tag
* Added authenticated_url() hook function to authutils.php for generating callback URLs
* Added EncoderIncludeOriginal job option that packages source media with encoding
* Fixed Timeline control tag attributes: audiotracks, videotracks and effecttracks 
* Fixed property issues related to multiple clip selection in Timeline
* Fixed mash property issue related to composited media trimming

Version 3.1.05
--------------
* Added PathSWF option to MovieMasher.xml for 'server' example so directory can be moved or renamed
* Added US-West and EU-West regions to Movie Masher Server AMI as well as US-East
* Changed path handling and include statements to better support windows deployments
* Fixed server path related issues in 'upload' example deployment
* Fixed errant static qualifiers for PHP class methods
* Fixed bug that kept switches containing underscores from being honored in DecoderSwitches option


Version 3.1.04
--------------
* Changed 'server' example to maintain different content for each authenticated user
* Added mash document management features to 'server' example - new, revert, load
* Added support to evaluate() for brackets after equals - eg. player.source={browser.selection.url}
* Added FLV upload support to 'server' example (though still preprocessed like other video)
* Changed 'server' example scripts to assume uploads with invalid mime type are interpreted as video
* Fixed bundling issue that prevented example/server/media/php/progress.php from being included
* Fixed media duration calculation that kept some transitions from rendering properly
* Fixed caching issue that kept frames of video used more than once in mash from rendering
* Added DecoderCacheAllVideoFrames option to work around any future video cache related issues
* Fixed timeline trimming of start times for images, transition and themes
* Added support for posting of REST transcoding jobs over HTTP (though this could be unsafe) 
* Fixed issue in Clip class that kept nested effects from being selected and edited

Version 3.1.03
--------------
* Fixed bug in Decoder.php that may have errantly reported invalid mash length.
* Added 'lengthseconds' property to clip, to facilitate editing by time instead of frame.
* Added Slider control to panel.xml bound to lengthseconds.
* Added inline documentation for several classes (MovieMasher, Fetchers, interfaces). 
* Refactored many ActionScript identifiers, hopefully to no effect. 
* Changed line breaks from Unix to Windows style in a few of the example files.

Version 3.1.02
--------------
* Added support for transitions based on Pixel Bender modules that create transparency masks
* Added new Chromakey effect, to facilitate green screen compositing, etc
* Added new Clouds theme, utilizing Perlin Noise filter to produce colorized animations
* Added new Toggle control for editing of on/off properties like 'player.play'
* Added 'player.stalling' property to facilitate loading indicator during playback 
* Added Mash 'quantize' property to control resolution of edits (see online documentation)
* Added more examples for Displacement effect - rain, ripple
* Changed behavior of Displacement effect - now uses greyscale bumpmap instead of alpha
* Changed Gradientmap theme to accommodate changes in Displacement effect
* Changed Timeline zoom property to represent percentage of mash that's visible - feedback welcome
* Fixed scaling issues in Decoder.php for image and video clips not having 'fill' of 'stretch' 
* Fixed issues with mouse dragging affecting certain platforms
* Fixed issues preventing use of Modules as preview icons (remember to fully qualify class)

Version 3.0.12
--------------
* Made the distribution available on Amazon's EC2 as Movie Masher Server
* Added example deployments that interact with Movie Masher Server
* Added support for browsing of RSS/Atom feeds (no example, sorry)
* Added support for browsing of YouTube and Flickr media
* Added support for other custom media sources
* Added beta support for YouTube chromeless player
* Added support for other custom media handlers
* Added support for event dispatching through evaluate API
* Added support for calling of parent functions through evaluate API
* Added support for hover border to items in Browser control
* Added support for clip specific tooltips in Browser and Timeline controls
* Changed 'fill' from a Media to a Clip property, so it's editable
* Switched to VideoPlayer class for video handling
* Fixed panel visibility bug related to window resizing
* Fixed several cache related bugs
* Fixed Timeline preview icon dislay bug
* Fixed looping of audio MP3s
* Moved com.moviemasher.control.CGI to Player SWF
* Note: configurations that contain 'source' tags having 'url' attributes
  must now also include a 'source' attribute pointing to the RemoteSource 
  class - see the media/xml/source.xml file in the 'server' example.
* Note: configurations containing 'media' tags having 'url' attributes ending
  with 'mp3', 'flv' or other video file extensions must now supply the new
  'handler' tag pointing to the relevant media handler class - see the
  media/xml/handler.xml file in the 'static' example.
* Note: video files with only audio tracks are no longer supported, sorry

Version 2.2.12
--------------
* Support added for JavaScript control of Movie Masher applet through ExternalInterface
* Support added for ActionScript loading and control of applet
* Better control over timeline clip appearance 
* Fixed bug that would rewind mash after play clicked a second time
* Fixed bug that make scrubbing while playing difficult

Version 2.1.06
--------------
* Fixed bug that kept player from refreshing in certain circumstances. 
* Fixed bug that was outputting debugging info on clip changes. 
* Fixed bug that would erroneously unload media when last frame of mash was accessed.

Version 2.1.05
--------------
* Fixed bug that disabled audio clip selection in Timeline 
* Fixed global volume muting of FLV files 
* Fixed inappropriate purge of assets when scrubbing


Version 2.1.04
--------------
* Added support for deleting of clips by dragging out of the Timeline 
* Fixed problem related to selecting audio clips in Timeline 
* Fixed Player refreshing of empty mashes 
* Fixed FLV positioning issues for non-resizing Player controls

Version 2.1.03
--------------
* Flash Player 10 or greater now required by end users 
* New Bender effect supports loading of external PBJ files 
* Added several new open source fonts to the static example 
* Updated version of swfObject, with new calling syntax and express install 
* Changed all line breaks in XML files to windows style (CRLF) 
* Fixed video positioning bug for dynamically sized players

Version 2.0.40
--------------
* Added Matte transition
* Added Shapes module
* Added 'split' property for Timeline control
* Fixed 'speed' property for video Clips

Version 2.0.39
--------------
* Changed default media options to supply correct path to media handlers

Version 2.0.38
--------------
* ActionScript 3 rewrite of code base
* FLV and h264 video support (beta)
* Better configuration of browser and timeline items
* Better control message handling
* More effect application options
* New CGI control for server interactions
* New Matte module for dynamic masking
* New Picturebox module for alternative compositing
* New Textbox module for alternative captioning
* New Colorize module for tinting
* Removed Imagewell control - use Browser instead
* Removed Scroller control, no replacement

Version 1.3.03
--------------
* Mouse-based clip trimming within the Timeline control
* More flexible media loading/filtering through the new 'Browserlist' control. 
* Added two other new modules as well: a 'Caption' effect and 'Text' control.

Version 1.3.02
--------------
* Major overhaul of the Timeline control
* Support for low resolution previews in the Browser

Version 1.3.01
--------------
* Fix for bug that kept media dragged from the browser from following the mouse during the drag operation.

Version 1.3.00
--------------
* Core applet file size reduced to 85k. 
* Source code streamlined for public release, and documented.