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


package com.moviemasher.type
{
	import flash.utils.*;
	import com.moviemasher.interfaces.*;

	public class Observed extends Observer implements IObserved
	{
		public function Observed()
		{
			_observableKeys = new Vector.<String>;
			__observers = new Dictionary;
			__tentativeValues = new Dictionary;
		}
		final public function addObservableKey(key:String):Boolean
		{
			var observable:Boolean = keyIsObservable(key);
			if (! observable)
			{
				_observableKeys.push(key);
			}
			return ! observable;
		}
		final public function removeObservableKey(key:String):Boolean
		{
			var pos:int = __indexOfObservableKey(key);
			
			
			var observable:Boolean = (pos != -1)
			if (observable) _observableKeys.splice(pos, 1);
			return observable;
		}
		final public function addObserverForKey(observer:IObserver, key:String):Boolean
		{
			var observers:Vector.<IObserver>;
			var observable:Boolean = keyIsObservable(key);
			if (observable)
			{
				if (__observers[key] == null) __observers[key] = new Vector.<IObserver>;
				observers = __observers[key];
				if (observers.indexOf(observer) == -1) observers.push(observer);
			}
			return observable;
		}
		final public function addObserverForKeyPath(observer:IObserver, path:String):Boolean
		{
			var i,z:uint;
			var value:*;
			var observed:IObserved = null;
			var keys:Array;
			var key:String;
			
			
			var observable:Boolean = keyIsObservable(path);
			
			if (observable)
			{
				keys = path.split('.');
				observable = (keys.length > 1);
			}
			if (observable)
			{
				key = keys.shift();
				value = valueForKey(key);
				observable = ((value != null) && (value is IObserved));
			}
			if (observable)
			{
				observed = value as IObserved;
				if (keys.length > 1) observable = observed.addObserverForKeyPath(this, keys.join('.'));
				else observable = observed.addObserverForKey(this, keys[0]);
			}
			if (observable)
			{
				addObserverForKey(observer, path);
			}
			return observable;
		}
		
		final public function keyIsObservable(key:String):Boolean
		{
			return (__indexOfObservableKey(key) != -1);
		}
		final public function removeObserverForKey(observer:IObserver, key:String):Boolean
		{
			return false;
		}
		final public function removeObserverForKeyPath(observer:IObserver, path:String):Boolean
		{
			return false;
		}
		final public function setValueForKey(value:*,key:String):Boolean
		{
			var k:String;
			var observer:IObserver;
			var observable:Boolean = keyIsObservable(key);
			var observers_vector:Vector.<IObserver> = null;
			var observers:Dictionary;
			var key_is_path:Boolean;
			if (observable)
			{
				value = _nearestValueForKey(value,key);
				__tentativeValues[key] = value;
				observers = __observersForKey(key);
				if (observers != null)
				{
					for (k in observers)
					{
						key_is_path = (k.indexOf('.') > -1);
						observers_vector = observers[k];
						for each (observer in observers_vector)
						{
							if (key_is_path) observer.willChangeValueForKeyPath(this, k);
							else observer.willChangeValueForKey(this, k);
						}
					}
				}
				delete __tentativeValues[key];
				_setValueForKey(value, key);
				
				if (observers != null)
				{
					for (k in observers)
					{
						key_is_path = (k.indexOf('.') > -1);
						observers_vector = observers[k];
						for each (observer in observers_vector)
						{
							if (key_is_path) observer.didChangeValueForKeyPath(this, k);
							else observer.didChangeValueForKey(this, k);
						}
					}
				}
			}
			return observable;
		}
		final public function setValueForKeyPath(value:*,path:String):Boolean
		{
			return false;
		}
		
		final public function tentativeValueForKey(key:String):*
		{
			return __tentativeValues[key];
		}
		final public function tentativeValueForKeyPath(path:String):*
		{
			//TODO
			return null;
		}
		final public function valueForKey(key:String):*
		{
			return _valueForKey(key);
		}
		final public function valueForKeyPath(path:String):*
		{
			return null;
		}
		
		override public function willChangeValueForKey(observed:IObserved, key:String):void
		{ }
		override public function willChangeValueForKeyPath(observed:IObserved, path:String):void
		{ }
		override public function didChangeValueForKey(observed:IObserved, key:String):void
		{ }
		override public function didChangeValueForKeyPath(observed:IObserved, path:String):void
		{ }

		protected function _nearestValueForKey(value:*,key:String):*
		{
			return value;		
		}
		protected function _setValueForKey(value:*, key:String):void
		{
			if (__values == null) __values = new Dictionary();
			__values[key] = value;
		}
		protected function _valueForKey(key:String):*
		{
			var value:* = null;
			if (__values != null)
			{
				value = __values[key];
			}
			return value;
		}
		private function __observersForKey(key:String):Dictionary
		{
			var k:String;
			var z:int = key.length + 1;
			var k_dot:String = key + '.';
			var observers:Dictionary = null;
			
			for (k in __observers)
			{
				if ((k == key) || (k.substr(0, z) == k_dot))
				{
					if (observers == null) observers = new Dictionary;
					observers[k] = __observers[k];
				}
			}
			return observers;
		}
		private function __indexOfObservableKey(key:String):int
		{
			var pos:int = key.indexOf('.');
			if (pos > -1) key = key.substr(0, pos);
			pos = _observableKeys.indexOf(key);
			return pos;
		}
		private var __observers:Dictionary;
		private var __tentativeValues:Dictionary;
		private var __values:Dictionary;
		protected var _observableKeys:Vector.<String>;
		
		
		
		
				
		override public function getValue(property:String):Value
		{
			addObservableKey(property);
			return new Value(valueForKey(property));
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			addObservableKey(property);
			setValueForKey(value.object, property);
			return false;
		}

	}
}