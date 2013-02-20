/*
* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
* 
* Software distributed under the License is distributed on an
* "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express
* or implied. See the License for the specific language
* governing rights and limitations under the License.
* 
* The Original Code is 'Movie Masher'. The Initial Developer
* of the Original Code is Doug Anarino. Portions created by
* Doug Anarino are Copyright (C) 2007-2012 Movie Masher, Inc.
* All Rights Reserved.
*/

package com.moviemasher.core
{
	import com.moviemasher.events.*;
	import com.moviemasher.display.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.system.*;
	import flash.utils.*;
	import org.bytearray.micrecorder.encoder.*;

/**
* Implementation class represents a temporary bytes based audio clip
* 
* @see IClip
*/
	public class AudioBytesClip extends Clip
	{
		public function AudioBytesClip(duration:Number, bytes:ByteArray, waveform:DisplayObject, data:Object = null)
		{
			__waveform = waveform;
			_bytes = bytes;
			_duration = duration;
			super('audio', null);
			var s,k:String;
			s = "<clip type='audio' id='" + IDUtility.generate() + "' lengthseconds='" + _duration + "' duration='" + _duration + "'";
			if (data != null)
			{
				for (k in data)
				{
					s += " " + k + "='" + data[k] + "'";
				}
			}
			s += "  />";
			tag = new XML(s);
		}
		override public function clone():IClip 
		{ 
			var data:Object = new Object;
			
			var props:Array = editableProperties();
			//RunClass.MovieMasher['msg']('editableProperties = ' + props);
			if (props.indexOf(ClipProperty.TRIMSTARTFRAME) == -1) props.push(ClipProperty.TRIMSTARTFRAME);
			if (props.indexOf(ClipProperty.TRIMENDFRAME) == -1) props.push(ClipProperty.TRIMENDFRAME);
			
			var prop:String;
			var i,z:int;
			z = props.length;
			for (i = 0; i < z; i++)
			{
				prop = props[i];
				data[prop] = getValue(prop).string;
				//RunClass.MovieMasher['msg'](prop + ' = ' + data[prop]);
			}
			var clip:IClip = new AudioBytesClip(_duration, _bytes, __waveform, data);
			return clip;
		}
		
		override public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
			// I have all my bytes, so always buffered
			return true;	
		}
		override public function buffer(range:TimeRange, mute:Boolean):void
		{
			// do nothing, because I'm buffered already	
		}
		override public function getValue(property:String):Value
		{
			var value:Value = null;
			
			switch(property)
			{
				case 'transfers':
					var encoder:IEncoder = new WaveEncoder();
					//RunClass.MovieMasher['msg'](this + '.getValue ' + property);
					var array:Array = new Array();
					array.push(new TransferBytes(getValue('id').string + '.wav', encoder.encode(_bytes)));
					value = new Value(array);
					break;
				case MediaProperty.WAVE:
					value = new Value(__waveform);
					break;
				default:
					value = super.getValue(property);
			}
			return value;
		}
		override protected function _moduleAudioDatum(position:uint, length:int, samples_per_frame:int):Vector.<AudioData>
		{
			
			var vector:Vector.<AudioData> = null;
			var multiplier:int = 8;
			var read:int;
			var i:int;
			var sample:Number;
			var still_needed:int;
			var read_position:int;	
			if (_bytes != null)
			{
				vector = new Vector.<AudioData>(1, true);
				var audio_data:AudioData = new AudioData();
				vector[0] = audio_data;
				
				audio_data.byteArray.position = 0;
				//RunClass.MovieMasher['msg'](this + '.getAudioDatum asking for ' + length + ' while length = ' +  audio_data.byteArray.length);
				/*
				if (position > (_duration * Sampling.SAMPLES_PER_SECOND))
				{
					position = position % (_duration * Sampling.SAMPLES_PER_SECOND);
				}
				*/
				read_position = position * 8;
				_bytes.position = read_position;
				/*
				
				for (i = 0; (i < length) && _bytes.bytesAvailable; i++)
				{
					audio_data.byteArray.writeFloat(_bytes.readFloat());
					audio_data.byteArray.writeFloat(_bytes.readFloat());
				}
				
				*/
				
				read = Math.min(_bytes.length - read_position, int(Math.round(Number(length) * multiplier)));
				
				//RunClass.MovieMasher['msg'](this + '.getAudioDatum _bytes.length = ' + _bytes.length + ' read_position = ' + read_position + ' read = ' + read);
					
				_bytes.readBytes(audio_data.byteArray, 0, read);
				//_sound.extract(audio_data.byteArray, length, position);
				still_needed = length - (audio_data.byteArray.length / multiplier);
				
				if (still_needed > 0)
				{
					RunClass.MovieMasher['msg'](this + '.getAudioDatum still_needed = ' + still_needed);
					//_sound.extract(audio_data.byteArray, still_needed, 0);
				//	_bytes.position = 0;
				//	_bytes.readBytes(audio_data.byteArray, audio_data.byteArray.length, still_needed * multiplier);
				
				}
			}
		
			return vector;
			
			
		}
		private var __waveform:DisplayObject;
		protected var _bytes:ByteArray;
		protected var _duration:Number;
	}

}
