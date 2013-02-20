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
	
	public class AudioRecorder extends CGI
	{
		function AudioRecorder()
		{
			_defaults.status_no_mic = 'Please attach audio input and try again...';
			_defaults.status_access_mic = 'Access to audio inputs was denied.';
			_defaults.status_scanning_mic = 'Detecting audio inputs...';
			_defaults.status_settings_access = 'Please enable access and try again...';
			_defaults.label_no_selected_mic = 'None selected';
			__noneMicID = RunClass.MD5['hash']('none')
			__selectedMicID = __noneMicID;
			
			
			_defaults.id = 'recorder';
			_defaults.rate = '44';
			_defaults.gain = '50';
			_defaults.echosuppression = '0';
			_defaults.silencelevel = '0';
			_defaults.silencetimeout = '2000';
			_defaults.loopback = '0';
			
			_defaults.status = '';
			_defaults.label = '';
			_defaults.labelpattern = '{recordmode.toUpperCase} {hours}:{minutes}:{seconds} {fullYear}-{month}-{date}';
			
			// these should not be overridden or changed
			_defaults.active = '0';
			_defaults.activity = '0';
			_defaults.audio = '1';
			_defaults.record = '0';
			_defaults.recorded = '0';
			_defaults.microphone = '';
			_defaults.microphones = '';
			_defaults.refresh = '';
			
		
		}
		override public function getValue(property:String):Value
		{
			var value:Value = null;
			
			switch(property)
			{
				case 'activity':
					value = new Value(__activityLevel);
					//RunClass.MovieMasher['msg']('AudioRecorder.getValue ' + property + ' "' + value.string + '"'); 
					break;
				case 'microphone':
					value = new Value(__selectedMicID);
					break;
				case 'microphones':
					value = new Value(__getMicrophones());
					break;
				case 'retry':
					value = (_okAudio ? new Value() : new Value('0'));
					break;
				case 'audio':
					value = (_okAudio ? super.getValue(property) : new Value());
					break;
				case 'record':
					value =  new Value(__record);
					break;
				default:
					value = super.getValue(property);
			}
			//RunClass.MovieMasher['msg']('AudioRecorder.getValue ' + property + ' "' + value.string + '"'); 
			return value;
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			var update:Boolean = true;
			var dispatch:Boolean = true;
				
			var record_changed:Boolean = false;
			//RunClass.MovieMasher['msg']('AudioRecorder.setValue ' + property + ' = ' + value.string);
			switch(property)
			{
			
				case 'rate':
				case 'echosuppression':
				case 'silencelevel':
				case 'silencetimeout':
				case 'loopback':
				case 'gain':
					_microphoneSetup();
					break;
				case 'activity':
					update = false;
					dispatch = false;
					//RunClass.MovieMasher['msg']('AudioRecorder.setValue ' + property + ' = ' + value.string);
					break;
				case 'refresh':
					property = 'microphones'; // so it updates
					update = false;
					break;
				case 'retry':
					_retry();
					update = false;
					break;
				case 'audio':
					record_changed = true;
					break;
				case 'recorded':
					record_changed = true;
					__recorded = value.boolean;
					break;
				case 'loaded': 
					break;
				case 'record':
					// start or stop recording based on state
					_setRecord(value.boolean);
					update = false;
					dispatch = false;
					break;
			}
			if (update)
			{
				// actually set the value and dispatch change to other controls
				super.setValue(value, property);
				_dispatchEvent(property);
			}
			if (record_changed) _dispatchEvent('record');			
			return false;
		}	
		protected function _startRecording():void
		{
			//var audio:Boolean = getValue('audio').boolean;
			setValue(new Value(_generateLabel()), 'label');
		 	//__meterDisplay(audio && _okAudio);
		}		
		protected function _stopRecording():void
		{
			// this enables play button the first time recording stops
			setValue(new Value(1), 'recorded');
			//__meterDisplay(false);
		}	
		final override protected function _adjustVisibility():void
		{ 
			try
			{
				if (_hidden) _destroy();
				else _retry();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.hidden ' + _hidden, e);
			}
		}
		final override protected function _release():void
		{
			// don't let clicks initiate url, etc...
		}
		
		protected function _destroy():void
		{
			__destroyAudio();
			_dispatchEvent('record');
			setValue(new Value(0), 'play');
		}
		private function __destroyAudio():void
		{
			if (_microphone != null)
			{
				//RunClass.MovieMasher['msg']('__destroyAudio');
					
				_microphone.removeEventListener(StatusEvent.STATUS, __statusAudio);
				_microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, __testSampling);
				_microphone = null;
				__meterDisplay(false);
			}
		}
		protected function _setRecord(boolean:Boolean):void
		{
			if (__record != boolean)
			{
				//RunClass.MovieMasher['msg'](this + '._setRecord ' + boolean);
				
				__record = boolean;
				if (__record) _startRecording();
				else _stopRecording();
				_dispatchEvent('record');
			}
		}
		private var __record:Boolean = false;
		final protected function _microphoneDetect():String
		{
			var error:String = '';
			
			if (_microphone == null)
			{
				_microphone = Microphone.getMicrophone();
				if (_microphone == null) error = 'status_no_mic';
				else 
				{
					_microphoneSetup();
					_microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, __testSampling);
					
					if (_microphone.muted) 
					{
						/*
						RunClass.MovieMasher['msg']('_microphoneDetect MUTED');
						_microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, __testSampling);
						
						if (! _displayedSettings)
						{
							_cgiSetStatus(getValue('status_settings_access').string);
							__settingsDisplay();
						}
						else
						{
							error = 'status_access_mic';
							__destroyAudio();
						}
						*/
					}
					else 
					{
						_okAudio = true;
						
					}
				}
			}
			return error;
		}
		final protected function _generateLabel():String
		{
			var label:String = '';
			label = getValue('labelpattern').string;
			if (label.length) label = RunClass.ParseUtility['brackets'](label, this);
			return label;
		}
		private function __meterDisplay(onORoff:Boolean):void
		{
			if (onORoff)
			{
				if (__audioTimer == null)
				{
					__audioTimer = new Timer(100);
					__audioTimer.addEventListener(TimerEvent.TIMER, __meterTimed);
					__audioTimer.start();
				}
			}
			else
			{
				if (__audioTimer != null)
				{
					__audioTimer.removeEventListener(TimerEvent.TIMER, __meterTimed);
					__audioTimer.stop();
					__audioTimer = null;
					__activityLevel = 0;
					_dispatchEvent('activity');
				}
			}
			
		}
		private function __meterTimed(e:TimerEvent):void
		{
			if (_microphone != null)
			{
				var cur_level:Number = Math.max(0, _microphone.activityLevel); // treat -1 like 0
				//RunClass.MovieMasher['msg']('AudioRecorder.__meterTimed ' + cur_level + ' ?= ' + __activityLevel);
				if (__activityLevel != cur_level)
				{
					__activityLevel = cur_level;
					_dispatchEvent('activity');
				}
			}
		}
		protected function _retry():void
		{
			var error:String = '';
			if (_accessDenied)
			{
				_accessDenied = false;
				_cgiSetStatus(getValue('status_settings_access').string);
				__settingsDisplay();
			}
			else
			{
				__destroyAudio();
				_cgiSetStatus(getValue('status_scanning_mic').string);
				
				_okAudio = false;
				_accessDenied = false;
				error = _microphoneDetect();
				if (error) _cgiSetStatus(getValue(error).string);
				//RunClass.MovieMasher['msg']('_retry DONE _microphoneDetect');
			}
		}
		private function __settingsDisplay():void
		{	
			_displayedSettings = true;
			Security.showSettings(SecurityPanel.PRIVACY);
		}
		protected function _microphoneSetup():void
		{
			//RunClass.MovieMasher['msg']('_microphoneSetup');
			/*
			_microphone.setSilenceLevel(0, 2000);
			_microphone.gain = 50;
			_microphone.rate = 44;
			*/
			_microphone.rate=getValue('rate').number; // Kbs
			_microphone.gain = getValue('gain').number;
			_microphone.setUseEchoSuppression(getValue('echosuppression').boolean);
			_microphone.setLoopBack(true);
			
			_microphone.setSilenceLevel(getValue('silencelevel').number, getValue('silencetimeout').number);
			if (! getValue('loopback').boolean)
			{
				var transform1:SoundTransform = _microphone.soundTransform;
				transform1.volume = 0;
				_microphone.soundTransform = transform1;
			}
		}
		private function __getMicrophones():Array
		{
			var a:Array = new Array();
			try
			{
				var i,z:int;
				z = Microphone.names.length;
				var object:Object;
				object = new Object();
				object.label = getValue('label_no_selected_mic').string;
				object.id = __noneMicID;
				a.push(object);
				for (i = 0; i < z; i++)
				{
					object = new Object();
					object.label = Microphone.names[i];
					object.id = RunClass.MD5['hash'](object.label);
					a.push(object);
				}
				//RunClass.MovieMasher['msg']('__getMicrophones ' + Microphone.names);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('__getMicrophones', e);
			}
			return a;
		}
		
		private function __testSampling(event:SampleDataEvent):void
		{
			//RunClass.MovieMasher['msg']('__testSampling');// removing listener ' + _microphone);
			if (_microphone != null) 
			{
				_okAudio = true;
				__meterDisplay(true);
				__selectedMicID = RunClass.MD5['hash'](_microphone.name);
				_dispatchEvent('microphone');
				_dispatchEvent('record');
				_dispatchEvent('audio');
				//RunClass.MovieMasher['msg']('_microphoneDetect mic = ' + getValue('microphone').string + ' ' + __selectedMicID);
				
				_microphone.addEventListener(StatusEvent.STATUS, __statusAudio);
				_microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, __testSampling);
				
			}	
		}
		private function __statusAudio(event:StatusEvent):void
		{
			//RunClass.MovieMasher['msg']('__statusAudio ' + event.code);
			var ok_audio:Boolean = _okAudio;
			switch(event.code)
			{
				case 'Microphone.Unmuted':
					_accessDenied = false;
					ok_audio = true;
					break;
				case 'Microphone.Muted':
					_accessDenied = true;
					ok_audio = false;
					break;
			}
			if (_okAudio != ok_audio)
			{	
				_okAudio = ok_audio;
				_dispatchEvent('audio');
			}
		}
		private var __selectedMicID:String;
		private var __noneMicID:String;
		
		private var __activityLevel:Number = 0; // last polled microphone level
		private var __audioTimer:Timer; 
		private var __recorded:Boolean;
		protected var _accessDenied:Boolean = false;
		protected var _microphone:Microphone;
		protected var _okAudio:Boolean;
		protected var _displayedSettings:Boolean = false;
 	}
}
