package org.bytearray.micrecorder
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.events.StatusEvent;
	import flash.media.*;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import org.bytearray.micrecorder.encoder.WaveEncoder;
	import org.bytearray.micrecorder.events.RecordingEvent;
	
	/**
	 * Dispatched during the recording of the audio stream coming from the microphone.
	 *
	 * @eventType org.bytearray.micrecorder.RecordingEvent.RECORDING
	 *
	 * * @example
	 * This example shows how to listen for such an event :
	 * <div class="listing">
	 * <pre>
	 *
	 * recorder.addEventListener ( RecordingEvent.RECORDING, onRecording );
	 * </pre>
	 * </div>
	 */
	[Event(name='recording', type='org.bytearray.micrecorder.RecordingEvent')]
	
	/**
	 * Dispatched when the creation of the output file is done.
	 *
	 * @eventType flash.events.Event.COMPLETE
	 *
	 * @example
	 * This example shows how to listen for such an event :
	 * <div class="listing">
	 * <pre>
	 *
	 * recorder.addEventListener ( Event.COMPLETE, onRecordComplete );
	 * </pre>
	 * </div>
	 */
	[Event(name='complete', type='flash.events.Event')]

	/**
	 * This tiny helper class allows you to quickly record the audio stream coming from the Microphone and save this as a physical file.
	 * A WavEncoder is bundled to save the audio stream as a WAV file
	 * @author Thibault Imbert - bytearray.org
	 * @version 1.2
	 * 
	 */	
	public final class MicRecorder extends EventDispatcher
	{
		private var _gain:uint;
		private var _rate:uint;
		private var _silenceLevel:uint;
		private var _timeOut:uint;
		private var _difference:uint;
		private var _microphone:Microphone;
		private var _buffer:ByteArray = new ByteArray();
		private var _output:ByteArray;
		private var _encoder:IEncoder;
		
		private var _completeEvent:Event = new Event ( Event.COMPLETE );
		private var _recordingEvent:RecordingEvent = new RecordingEvent( RecordingEvent.RECORDING, 0 );
		public function get recordingEvent():RecordingEvent
		{
			return _recordingEvent;
		}
		/**
		 * 
		 * @param encoder The audio encoder to use
		 * @param microphone The microphone device to use
		 * @param gain The gain
		 * @param rate Audio rate
		 * @param silenceLevel The silence level
		 * @param timeOut The timeout
		 * 
		 */		
		public function MicRecorder(encoder:IEncoder, microphone:Microphone=null, gain:uint=100, rate:uint=44, silenceLevel:uint=0, timeOut:uint=4000)
		{
			_encoder = encoder;
			_microphone = microphone;
			_gain = gain;
			_rate = rate;
			_silenceLevel = silenceLevel;
			_timeOut = timeOut;
		}
		
		/**
		 * Starts recording from the default or specified microphone.
		 * The first time the record() method is called the settings manager may pop-up to request access to the Microphone.
		 */		
		public function record():void
		{
			//Enhanced
			if ( _microphone == null ) _microphone = Microphone.getMicrophone();
			//_microphone.setUseEchoSuppression(true); 
			_difference = getTimer();
			//_microphone.setLoopBack(true);
			_microphone.setSilenceLevel(0, 2000);
			_microphone.gain = 50;
			_microphone.rate = _rate;
			_buffer.length = 0;
			/*
			var options:MicrophoneEnhancedOptions = microphone.enhancedOptions;
			options.autoGain = false;

			options.mode = MicrophoneEnhancedMode.FULL_DUPLEX;
			options.echoPath = 128;
			options.nonLinearProcessing = true;
			*/

			
			_microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			_microphone.addEventListener(StatusEvent.STATUS, onStatus);
		}
		
		private function onStatus(event:StatusEvent):void
		{
			_difference = getTimer();
		}
		
		/**
		 * Dispatched during the recording.
		 * @param event
		 	
		private function onTrigger(event:SampleDataEvent):void
		{
			_microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, onTrigger);
			_microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			
		}
		*/	
		private function onSampleData(event:SampleDataEvent):void
		{
			_recordingEvent.time = getTimer() - _difference;
			_recordingEvent.position = event.position;
			_recordingEvent.sampleEvent = event;
			
			event.data.position = 0;
			while(event.data.bytesAvailable > 0)
				_buffer.writeFloat(event.data.readFloat());
			dispatchEvent( _recordingEvent );
		}
		
		/**
		 * Stop recording the audio stream and automatically starts the packaging of the output file.
		 */		
		public function stop():void
		{

			_microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
		//	_microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, onTrigger);
			
			_buffer.position = 0;
			
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get gain():uint
		{
			return _gain;
		}

		/**
		 * 
		 * @param value
		 * 
		 */		
		public function set gain(value:uint):void
		{
			_gain = value;
		}

		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get rate():uint
		{
			return _rate;
		}

		/**
		 * 
		 * @param value
		 * 
		 */		
		public function set rate(value:uint):void
		{
			_rate = value;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get silenceLevel():uint
		{
			return _silenceLevel;
		}

		/**
		 * 
		 * @param value
		 * 
		 */		
		public function set silenceLevel(value:uint):void
		{
			_silenceLevel = value;
		}


		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get microphone():Microphone
		{
			return _microphone;
		}

		/**
		 * 
		 * @param value
		 * 
		 */		
		public function set microphone(value:Microphone):void
		{
			_microphone = value;
		}

		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get output():ByteArray
		{
			if (! _output)
			{
				_output = _encoder.encode(_buffer, 1);
			
				dispatchEvent( _completeEvent );
			}
			return _output;
		}
		public function get buffer():ByteArray
		{
			return _buffer;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public override function toString():String
		{
			return "[MicRecorder gain=" + _gain + " rate=" + _rate + " silenceLevel=" + _silenceLevel + " timeOut=" + _timeOut + " microphone:" + _microphone + "]";
		}
		private var __latency:Number=0.0; // in milliseconds
		private var __latencyModified:Number = 0.0; // time - moment __latency last updated
	}
}