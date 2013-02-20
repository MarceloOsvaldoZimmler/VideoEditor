package com.moviemasher.control
{
	import com.moviemasher.action.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.control.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
	import ktu.events.*;
	import ktu.media.*;
	
	public class Recorder extends AudioRecorder
	{
		function Recorder()
		{
			_defaults.status_no_cam = 'Please attach video input and try again...';
			_defaults.status_access_cam = 'Access to video inputs was denied.';
			_defaults.status_scanning_cam = 'Detecting video inputs...';

			// these options can be overridden in the control tag 
			_defaults.keyframeinterval = '12';
			_defaults.fps = '15';
			_defaults.bandwidth = '0';
			_defaults.quality = '80';
			_defaults.rtmpurl = '';
			
			_defaults.host = '';
			
			
			_defaults.filepattern = '';
			// these should not be overridden or changed
			_defaults.video = '1';
			_defaults.preview = '0';
			_defaults.recordmode = '';
		
		}
		override public function resize():void
		{
			if (__outVideo == null)
			{		
				__outVideo=new Video(_width,_height);
				__outVideo.name = '__outVideo';
				addChild(__outVideo);
				if (__camera != null) __outVideo.attachCamera(__camera);
			}
			if (__inVideo == null)
			{
				__inVideo=new Video(_width,_height);
				__inVideo.visible = false; // initially invisible, until we play back
				__inVideo.name = '__inVideo';
				addChild(__inVideo);
			}
			__display(__outVideo);
		}
		override public function getValue(property:String):Value
		{
			var value:Value = null;
			
			switch(property)
			{
				case 'recordmode':
					value = new Value(((__okVideo && getValue('video').boolean) ? 'video' : ((_okAudio && getValue('audio').boolean) ? 'audio' : null)));
					break;
				case 'host':
					value = super.getValue(property);
					//RunClass.MovieMasher['msg'](this + '.getValue ' + property + ' ' + value.string);
					break;
				case 'retry':
					value = ((_okAudio && __okVideo) ? new Value() : new Value('0'));
					break;
				case 'video':
					value = (__okVideo ? super.getValue(property) : new Value());
					break;
				case 'play':
					value = (((! _hidden) && getValue('recorded').boolean) ? super.getValue(property) : new Value());
					break;
				case 'record':
					value = ((__okConnection && ((__okVideo && getValue('video').boolean) || (_okAudio && getValue('audio').boolean))) ? super.getValue(property) : new Value());
					break;
				case 'streamname':
					value = new Value(__streamName);
					break;
				default:
					value = super.getValue(property);
			}
			return value;
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			var update:Boolean = true;
			var record_changed:Boolean = false;
			var reset_display:Boolean = false;
			switch(property)
			{
				case 'video':
					record_changed = true;
					reset_display = true;
					break;
				case 'save':
					setValue(new Value(), 'recorded');
					__save();
					update = false;
					break;
				case 'record':
					if (! value.boolean) __destroyOutStream();					
					break;
				case 'play':
					// start or stop playback of recorded stream
					if (value.boolean) __startPlay();
					else __destroyInStream();
					break;
				case 'recorded':
					record_changed = true;
					if (! value.boolean) reset_display = true;
					break;				
			}
			if (update)
			{
				// actually set the value and dispatch change to other controls
				super.setValue(value, property);
			}
			if (record_changed) _dispatchEvent('play');
			if (reset_display) __resetDisplay();
			return false;
		}
		override protected function _destroy():void
		{
			__destroyOutStream();
			__destroyInStream();
			__destroyVideo();
			super._destroy(); // destroys _microphone
			__destroyConnection();
			__destroyCameraDetection();
		}
		override protected function _retry():void
		{
			super._retry(); // sets _okAudio and _accessDenied
			if (! _accessDenied)
			{
				_cgiSetStatus(getValue('status_scanning_cam').string);
				__destroyConnection();
				__destroyVideo();
				__okVideo = false;
				__okConnection = false;
				__createCameraDetection();
			}
		}
		override protected function _startRecording():void
		{
			super._startRecording();
			
			var audio:Boolean = getValue('audio').boolean;
			var video:Boolean = getValue('video').boolean;
			var recordmode:String = getValue('recordmode').string;
			if (! __createOutStream()) _cgiSetStatus('Could not create recording stream');
			else
			{
				__updateStreamName(recordmode);
				if (audio) __outStream.attachAudio(_microphone);
				if (video) __outStream.attachCamera(__camera);
				__outStream.publish(__streamName, "record");
			 }
		}
		private function __cameraDetected(event:CameraDetectionEvent):void 
		{
			var ok_video:Boolean = __okVideo;
			var ok_audio:Boolean = _okAudio;
			var error:String = '';
			//RunClass.MovieMasher['msg'](this + '.__cameraDetected');
			try
			{
				
				switch (event.code) 
				{
					case CameraDetectionResult.SUCCESS :
						__camera = event.camera;
						__okVideo = true;
						__setupCamera();
						break;
					case CameraDetectionResult.NO_PERMISSION :
						_accessDenied = true;
						error = 'status_access_cam';
						break;
					case CameraDetectionResult.NO_CAMERAS :
						error = 'status_no_cam';
						break;
				}
				
				if (ok_video != __okVideo) _dispatchEvent('video');

				_dispatchEvent('retry');
				if (_okAudio && __okVideo) _cgiSetStatus('');
				else if (error.length)  _cgiSetStatus(getValue(error).string);
				if (_okAudio || __okVideo) __createConnection();
			//	if (!__okVideo) __settingsDisplay();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__cameraDetected', e);
			}	
		}
		private function __createCameraDetection():void
		{
			try
			{
				var s:Stage = RunClass.MovieMasher['instance'].stage;
				if (s)
				{
					__cameraDetection = new CameraDetection(s);
					if (__cameraDetection != null)
					{
						__cameraDetection.addEventListener (CameraDetectionEvent.RESOLVE, __cameraDetected);
						try
						{
							__cameraDetection.begin();
						}
						catch(e:*)
						{
							RunClass.MovieMasher['msg'](this + '.__createCameraDetection begin ' + __cameraDetection, e);
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__createCameraDetection', e);
			}
		}
		private function __createConnection():void
		{
			var rtmpurl:String;
			try
			{
				if (__netConnection == null)
				{
					rtmpurl = getValue('rtmpurl').string;
					if (rtmpurl.length)
					{
						rtmpurl = RunClass.ParseUtility['brackets'](rtmpurl);
						if (rtmpurl.length)
						{
							__netConnection = new NetConnection();
							__netConnection.addEventListener(NetStatusEvent.NET_STATUS,__statusConnection);
							__netConnection.connect(rtmpurl);
							//RunClass.MovieMasher['msg'](this + '.__createConnection ' + __netConnection + ' ' + rtmpurl);
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__createConnection ' + rtmpurl + ' ' + RunClass.ParseUtility['brackets'], e);
			}
		}
		private function __createInStream():Boolean
		{
			var ok:Boolean = (__inStream != null);
			try
			{
				if (! ok)
				{
					__inStream = new NetStream(__netConnection);
					ok = (__inStream != null);
					if (ok)
					{
						__inClient=new Object();
						__inClient.onMetaData=__onMetaData;
						__inStream.client=__inClient;
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__createInStream', e);
			}
			return ok;
		}
		private function __createOutStream():Boolean
		{
			var ok:Boolean = (__outStream != null);
			try
			{
				if (! ok)
				{
					__outStream = new NetStream(__netConnection);
					ok = (__outStream != null);
					if (ok)
					{
						__outClient=new Object();
						__outClient.onMetaData=__onMetaData;
						__outStream.client=__outClient;
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__createOutStream ' + __netConnection, e);
			}
			return ok;
		}
		private function __destroyCameraDetection():void
		{
			if (__cameraDetection != null)
			{
				__cameraDetection.dispose();
				__cameraDetection = null;
			}
		}
		private function __destroyConnection():void
		{
			if (__netConnection != null)
			{
				__netConnection.close();
				__netConnection = null;
			}
		}
		private function __destroyInStream():void
		{
			if (__inStream != null)
			{
				__inVideo.attachNetStream(null);
				__inClient.onPlayStatus = null;
			 	__inStream.close();
			 	__inStream = null;
			}
		}
		private function __destroyOutStream():void
		{
			if (__outStream != null)
			{
				__outStream.attachCamera(null);
				__outStream.attachAudio(null);
			 	__outStream.close();
			 	__outStream = null;
			}
		}
		private function __destroyVideo():void
		{
			if (__camera != null)
			{
				__camera.removeEventListener(StatusEvent.STATUS, __statusVideo);
				__camera = null;
			}
		}
		private function __display(displayObject:DisplayObject, bitmapData:BitmapData = null):void
		{
			var bm:Bitmap;
			var bmd:BitmapData;
			if (__displayObject != displayObject)
			{
				if (__displayObject != null)
				{
					if (__displayObject is Bitmap)
					{
						bm = __displayObject as Bitmap;
						bmd = bm.bitmapData;
						if (bmd != null)
						{
							bm.bitmapData = null;
							bmd.dispose();
						}
					}

					__displayObject.visible = false;
				}
				__displayObject = displayObject;
				if (__displayObject != null)
				{
					if (__displayObject is Bitmap)
					{
						bm = __displayObject as Bitmap;
						bm.bitmapData = bitmapData;

					}

					__displayObject.visible = true;
				}
			}
		}
		private function __onMetaData(mdata:Object):void
		{
			 //Dummy to avoid error
		}		
		private function __onPlayStatus(status:Object):void
		{
			if (status.code == 'NetStream.Play.Complete')
			{
				setValue(new Value(0), 'preview')
			}
		}
		private function __requestURL(type:String, funct:Function, data:ByteArray = null):Boolean
		{
			var did:Boolean = false;
			var url:String = getValue(type + 'url').string;
			if (url.length)
			{
				did = true;
				if (__loader == null)
				{
					url = RunClass.ParseUtility['brackets'](url);
					if (url.length)
					{
						__loader = RunClass.MovieMasher['dataFetcher'](url, data);
						__loader.addEventListener(Event.COMPLETE, funct);
					}
				}
			}
			return did;
		}
		private function __resetDisplay():void
		{
			__display(getValue('video').boolean ? __outVideo : null);
		}
		private function __save(event:Event = null):void
		{
			_cgiSetStatus('Saving...');
			setValue(new Value(10), 'progress');
			__display(null);
			super._release(); // bypass my override, which does nothing
		}
		private function __setupCamera():void
		{
			__camera.addEventListener(StatusEvent.STATUS, __statusVideo);
			__camera.setKeyFrameInterval (getValue('keyframeinterval').number);
			__camera.setMode (_width,_height,getValue('fps').number);
			__camera.setQuality (getValue('bandwidth').number, getValue('quality').number)
			if (__outVideo != null) __outVideo.attachCamera(__camera);
					
		}
		private function __startPlay():void
		{
			try
			{
				__createInStream();
				if (__inClient != null)
				{
					__inClient.onPlayStatus = __onPlayStatus;
					__inStream.play(__streamName);
					if (getValue('video').boolean)
					{
						__inVideo.attachNetStream(__inStream);
						__display(__inVideo);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__startPlay', e);
			}
		}
		private function __statusConnection(event:NetStatusEvent):void
		{
			//RunClass.MovieMasher['msg'](this + '.__statusConnection ' + event.info.code);
			switch (event.info.code)
			 {
				case "NetConnection.Connect.Closed":
				case "NetConnection.Connect.Failed":
					__okConnection = false;
					
					break;
			 	case "NetConnection.Connect.Success":
			 		__okConnection = true;
					_dispatchEvent('record');
				   break;
			}
		}
		private function __statusVideo(event:StatusEvent):void
		{
			//RunClass.MovieMasher['msg'](this + '.__statusVideo ' + event.code);
			var muted:Boolean =(event.code != 'Camera.Unmuted');
			setValue(new Value(muted ? 0 : 1), 'videoready');
		}
		private function __updateStreamName(mode:String):void
		{
			//var player:IPropertied = RunClass.MovieMasher['getByID'](ReservedID.PLAYER) as IPropertied;
			__streamName = mode + '_';
			__streamName += IDUtility.generate();
			setValue(new Value(__streamName), 'streamname');
		}
		private var __activityLevel:Number; // last polled microphone level
		private var __audioTimer:Timer; 
		private var __camera:Camera;
		private var __cameraDetection:CameraDetection;
		private var __displayObject:DisplayObject = null;
		private var __fileSize:Number;
		private var __inClient:Object;
		private var __inStream:NetStream;
		private var __inVideo:Video;
		private var __loader:IDataFetcher;
		private var __netConnection:NetConnection;
		private var __okConnection:Boolean;
		private var __okVideo:Boolean;
		private var __outClient:Object;
		private var __outStream:NetStream;
		private var __outVideo:Video;
		private var __streamName:String;
		
 	}
}
