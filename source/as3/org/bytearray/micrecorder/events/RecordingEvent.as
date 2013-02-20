package org.bytearray.micrecorder.events
{
	import flash.events.*;
	
	public final class RecordingEvent extends Event
	{
		public static const RECORDING:String = "recording";
		
		private var _time:Number;
		
		/**
		 * 
		 * @param type
		 * @param time
		 * 
		 */		
		public function RecordingEvent(type:String, time:Number, e:SampleDataEvent = null, p:Number = NaN)
		{
			super(type, false, false);
			_time = time;
			_sampleEvent = e;
			_position = p;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get time():Number
		{
			return _time;
		}

		/**
		 * 
		 * @param value
		 * 
		 */		
		public function set time(value:Number):void
		{
			_time = value;
		}
		protected var _position:Number;
		public function get position():Number
		{
			return _position;
		}

		/**
		 * 
		 * @param value
		 * 
		 */		
		public function set position(value:Number):void
		{
			_position = value;
		}
		protected var _sampleEvent:SampleDataEvent;
		public function get sampleEvent():SampleDataEvent
		{
			return _sampleEvent;
		}

		/**
		 * 
		 * @param value
		 * 
		 */		
		public function set sampleEvent(value:SampleDataEvent):void
		{
			_sampleEvent = value;
		}

		/**
		 * 
		 * @return 
		 * 
		 */		
		public override function clone(): Event
		{
			return new RecordingEvent(type, _time, _sampleEvent, _position)
		}
	}
}