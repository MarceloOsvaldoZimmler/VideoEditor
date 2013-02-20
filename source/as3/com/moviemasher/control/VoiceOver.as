package com.moviemasher.control
{
	import com.moviemasher.action.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.core.*;
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

	import org.bytearray.micrecorder.*;
	import org.bytearray.micrecorder.events.*;
	import org.bytearray.micrecorder.encoder.*;
	
	public class VoiceOver extends AudioRecorder
	{
		
		function VoiceOver()
		{
			// these options can be overridden in the control tag 
			_defaults.id = 'voiceover';
			_defaults.rate = '44';
			_defaults.rewind = '1';
			_defaults.filepattern = '';
			_defaults.labelpattern = '{recordmode.toUpperCase} {hours}:{minutes}:{seconds} {fullYear}-{month}-{date}';
		}
		private var __seeking:Number;
		override protected function _startRecording():void
		{
			//RunClass.MovieMasher['msg'](this + '._startRecording');
			super._startRecording();
			__player = RunClass.MovieMasher['getByID'](ReservedID.PLAYER) as IControl;
			if (__player != null)
			{
			
				var mash:IMash = __player.getValue('mash').object as IMash;
				__mash = mash;
				//RunClass.MovieMasher['msg'](this + '._startRecording stopping player');
				__player.setValue(new Value(0), 'play');
				__player.setValue(new Value(1), PlayerProperty.AUTOSTOP);
				var completed:Number = __player.getValue(PlayerProperty.COMPLETED).number;
				__seeking = (getValue('rewind').boolean ? 0 : completed);
				if (__seeking != completed) 
				{
					__player.setValue(new Value(__seeking), PlayerProperty.COMPLETED);
					completed = __player.getValue(PlayerProperty.COMPLETED).number;
				}
				if (__seeking != completed) __player.addEventListener(PlayerProperty.COMPLETED, __playerQueued);
				else __playerQueued(null);
			}
			else RunClass.MovieMasher['msg'](this + '._startRecording NO PLAYER');
		}
		private var __stopTimer:Timer;
		
		override protected function _stopRecording():void
		{
			//RunClass.MovieMasher['msg'](this + '._stopRecording ');
			__recorder.removeEventListener( RecordingEvent.RECORDING, __recordingRecorder);
			__recorder.stop();
			
			__player.removeEventListener(PlayerProperty.PLAY, __playerDone);
			__player.setValue(new Value(0), PlayerProperty.PLAY);
			__stopTimer = new Timer(1000);
			__stopTimer.addEventListener(TimerEvent.TIMER, __timerStop);
			__stopTimer.start();
		}
		private function __timerDraw(event:Event):void
		{
			try
			{
				var sample:Number;
				var half:Number = .5;
				var last_sample:Number;
				var stop_time:Number = (new Date()).getTime() + 1000; // one sec
				var done:Boolean = false;
				var last_x,x_pos:uint;
				
				while ((! done) && ((new Date()).getTime() < stop_time))
				{
					done = (! __recorder.buffer.bytesAvailable);
					if (! done)
					{
						sample = __recorder.buffer.readFloat();
						// write sample twice to make stereo
						__renderedBytes.writeFloat(sample);
						__renderedBytes.writeFloat(sample);
						if (last_sample != sample)
						{
							last_sample = sample;
							x_pos = __waveformSize.width * (__renderedBytes.length / __recordedBytes);
							if (last_x != x_pos)
							{
								last_x = x_pos;
								__waveformGraphics.lineTo(x_pos, (sample * __waveformSize.height + __waveformSize.height * half) );
							}
						}
					}
				}
				if (done)
				{
					__stopTimer.removeEventListener(TimerEvent.TIMER, __timerDraw);
					__stopTimer.addEventListener(TimerEvent.TIMER, __timerDone);
				}
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__timerDraw ', e);
			}
		}
		private function __timerDone(event:Event):void
		{
			__stopTimer.removeEventListener(TimerEvent.TIMER, __timerDone);
			__stopTimer.addEventListener(TimerEvent.TIMER, __timerCreate);
			
			
			
			var bmd:BitmapData = new BitmapData(__waveformSize.width, __waveformSize.height);
			bmd.draw(__waveformSprite);
			var bm:Bitmap = new Bitmap();
			bm.bitmapData = bmd;
			
			__waveformSprite = bm;
			
			
			//RunClass.MovieMasher['msg'](this + '.__timerDraw done ' + __renderedBytes.length + ' of ' + __recordedBytes);
		}
		private function __timerCreate(event:Event):void
		{
			__stopTimer.removeEventListener(TimerEvent.TIMER, __timerCreate);
			__stopTimer.stop();
			__stopTimer = null;
			
			
			super._stopRecording();
			
			var clip:IClip = new AudioBytesClip((((__renderedBytes.length) / Sampling.SAMPLES_PER_SECOND) / Sampling.BYTES_PER_SAMPLE), __renderedBytes, __waveformSprite);
			var items:Array = new Array();
			items.push(clip);
			var track:uint = __mash.freeTrack(clip.startFrame, clip.startFrame + clip.lengthFrame, clip.type, 1);
			new ClipsTimeAction(__mash, items, track, clip.startTime);
	
			__destroyAudio();
			
			__waveformSprite = null;
			__waveformGraphics = null;
			__waveformSize = null;
			
		}
		private function __timerStop(event:Event):void
		{
			try
			{
			
				__stopTimer.removeEventListener(TimerEvent.TIMER, __timerStop);				
				var byte_time:Number = (((__recorder.buffer.length) / Sampling.SAMPLES_PER_SECOND) / 4);
				var difference:int = Sampling.MIC_LATENCY + ((__recordingTime - byte_time) * Sampling.SAMPLES_PER_SECOND) - (__recordingSample / 4);
				__renderedBytes = new ByteArray();
				var position:Number = - difference * 4;
				var i:Number;
				if (position < 0)
				{
					for (i = 0; i < difference; i++)
					{
						__renderedBytes.writeFloat(0.0);
					}
					position = 0;
				}
				__recorder.buffer.position = position;
				__recordedBytes = __renderedBytes.position + (2 * (__recorder.buffer.length - __recorder.buffer.position));
				__waveformSize = __sizeFromDuration(((__recordedBytes / Sampling.SAMPLES_PER_SECOND) / Sampling.BYTES_PER_SAMPLE));
				__createWaveform();
				__stopTimer.addEventListener(TimerEvent.TIMER, __timerDraw);
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__timerStop ' + __renderedBytes.length + ' ' +  __recorder.buffer.length, e);
			}
		}	
		private function __createWaveform():void
		{
			try
			{
				var sprite:Sprite = new Sprite();
				__waveformSprite = sprite;
				//stage.addChild(__waveformSprite);
				__waveformGraphics = sprite.graphics;
				
				// fill with white and draw center line
				RunClass.DrawUtility['fill'](__waveformGraphics, __waveformSize.width, __waveformSize.height, 0xFFFFFF);
				__waveformGraphics.lineStyle(1, 0x000000);
				__waveformGraphics.moveTo(__waveformSize.width, __waveformSize.height * .5 );
				__waveformGraphics.lineTo( 0, __waveformSize.height * .5 );
				//if (__waveformX) __waveformGraphics.moveTo(__waveformX, __waveformSize.height * .5 );
				
				//__waveformSprite.width = stage.stageWidth;
				
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__createWaveform ', e);
			}
		}
		private function __sizeFromDuration(seconds:Number):Size
		{
			return new Size(8000, 50);
		}
		private function __playerQueued(event:Event):void
		{
			var completed:Number = __player.getValue(PlayerProperty.COMPLETED).number;
			//RunClass.MovieMasher['msg'](this + '.__playerQueued completed = ' + completed + ' __seeking = ' + __seeking);
				
			if (completed == __seeking)
			{
				__player.removeEventListener(PlayerProperty.COMPLETED, __playerQueued);
				__destroyAudio();
				__createAudio();
				__player.setValue(new Value(1), 'play');
				__player.addEventListener(PlayerProperty.PLAY, __playerDone);
				__recorder.record();
			}
		}
		private function __playerDone(event:Event):void
		{

			if (! __player.getValue(PlayerProperty.PLAY).boolean)
			{
				_setRecord(false);
			}
		}		
		private function __createAudio():void
		{
			if (__recorder == null)
			{
				__recorder = new MicRecorder(new WaveEncoder(), _microphone, 50, Sampling.SAMPLES_PER_SECOND);
				__recorder.addEventListener( RecordingEvent.RECORDING, __recordingRecorder);
				
			}
			else RunClass.MovieMasher['msg'](this + '.__createAudio with existing __recorder');
			
		}
		private function __destroyAudio():void
		{
			if (__recorder != null)
			{
				__recorder.stop();
				__recorder.removeEventListener( RecordingEvent.RECORDING, __recordingRecorder);
				__recorder = null;
			}
			//else RunClass.MovieMasher['msg'](this + '.__destroyAudio with no __recorder');

		}		
		private function __realFromPosition(n:Number, rate:Number = 1.0):Number
		{
			n = n / Sampling.SAMPLES_PER_MILLISECOND; // convert from samples to milliseconds
			//if (rate != 1.0) n = n / rate; // scale the time by rate
			var latency:Number = __mash.latency;
			var latency_time:Number = __mash.latencyUpdated;
			
			n -= latency; // remove the buffer
			if (latency_time)
			{
				// add in how much of the buffer we've actually played 
				n += ((new Date()).getTime() - latency_time);
			}
		
			n = n / 1000; // covert from milliseconds to seconds
			return n;
		}		
		private function __recordingRecorder(event:RecordingEvent):void
		{
			__recordingSample = event.sampleEvent.data.position;
			__recordingTime = __realFromPosition(__mash.sample);
			
			//RunClass.MovieMasher['msg']('__recordingTime = ' + __recordingTime + ' ' + PlayerProperty.LOCATION + ' = ' + __player.getValue(PlayerProperty.LOCATION).string);

		}
		private var __difference:Number = 0;
		private var __recordedBytes:Number;
		private var __displayObject:DisplayObject = null;
		private var __mash:IMash;
		private var __player:IControl;
		private var __recorder:MicRecorder;
		private var __recordingSample:Number;
		private var __recordingTime:Number;
		private var __renderedBytes:ByteArray;
		private var __waveformGraphics:Graphics;
		//private var __waveformSample:Number;
		private var __renderingBytes:Number;
//		private var __waveformSamplesPerPixel:Number;
//		private var __renderedBytesPosition:Number;
//		private var __recorderBufferPosition:Number;
		private var __waveformSize:Size;
		private var __waveformSprite:DisplayObject;
		private var __waveformX:uint;

 	}
}
