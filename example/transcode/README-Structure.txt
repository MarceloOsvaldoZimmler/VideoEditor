
File Structure Read Me
----------------------

After running the example and uploading a video, audio and image file the media directory 
would look something like this:

transcoder:
	media:
		user: 
			USER_ID: folder will be named after the username provided during authentication
				5D91B16A-D68A-416D-924F-5103713F125A: unique ID for this Quicktime video file
					256x144x12: low resolution encodings used in editor (width x height x fps)
						01.jpg
						...
						40.jpg
					audio.mp3: soundtrack
					audio.png: waveform graphic
					original.mov: original asset used by renderer
					meta: information about the asset
						audio.txt: will not be empty() if audio track exists (derived from ffmpeg.txt)
						dimensions.txt: contains width x height of original (derived from ffmpeg.txt)
						duration.txt: contains float representing seconds (derived from ffmpeg.txt)
						extension.txt: file extension of original used to determine path from ID
						label.txt: the original file name when uploaded
						type.txt: audio, image or video (derived from Content-Type.txt)
				7AB99693-7E1F-4047-A92E-C98F1DDAAF8C: unique ID for this MP3 audio file
					audio.mp3: low resolution encoding used in editor
					audio.png: waveform graphic
					original.mp3: original asset used by renderer
					meta: information about the asset
						audio.txt: will not be empty() since audio track exists (derived from ffmpeg.txt)
						duration.txt: contains float representing seconds (derived from ffmpeg.txt)
						extension.txt: file extension of original used to determine path from ID
						label.txt: the original file name when uploaded
						type.txt: audio, image or video (derived from Content-Type.txt)
				14ABAF94-E2BB-426B-87D0-8E2CE243A5B4: unique ID for this PNG image file
					256x144x1: low resolution encodings used in editor
						0.png
					original.png: original asset used by renderer
					meta: information about the asset
						dimensions.txt: contains width x height of original (derived from ffmpeg.txt)
						extension.txt: file extension of original used to determine path from ID
						label.txt: the original file name when uploaded
						type.txt: audio, image or video (derived from Content-Type.txt)
						