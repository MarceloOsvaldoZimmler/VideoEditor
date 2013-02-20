/*
* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
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

package  com.moviemasher.action
{
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import flash.events.*;
/**
* Abstract base class with static functions to manage history queue of {@link Action} objects.
*
* @see Selection
* @see Timeline
*/
	public class Action
	{
	
/**
* Static function removes entire action history queue.
*/
		public static function clear() : void
		{
			doStack = [];
			currentDo = -1;
			eventDispatcher.dispatchEvent(new ActionEvent());
		}
/**
* Static function initiates next undone action in history queue.
*/
		public static function redo() : void
		{
			if (currentDo < doStack.length - 1)
			{
				currentDo ++;
				var action:Action = doStack[currentDo];
				if (! action.done) action._redoSelf();
			}
		}
/**
* Static function undoes last done action in history queue.
*/
		public static function undo() : void
		{
			if (currentDo > -1)
			{
				var action:Action = doStack[currentDo];
				action._undoSelf();
				currentDo --;
				eventDispatcher.dispatchEvent(new ActionEvent(action, true));
			}
		}
		public static var currentDo : Number = -1;
		public static var doStack : Array = [];
		public static var eventDispatcher:EventDispatcher = new EventDispatcher();
/**
* Constructor for all {@link Action} objects. 
*
* @param done Boolean indicating whether or not action needs doing.
*/
		public function Action(done:Boolean = false)
		{
			_done = done;
			__push();
		}
		protected final function _redoSelf():void
		{
			try
			{
				_redo();
				_done = true;
				eventDispatcher.dispatchEvent(new ActionEvent(this));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		protected final function _undoSelf():void
		{
			try
			{
				_undo();
				_done = false;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
/**
* Array of {@link ISelectable} objects to be selected, based on done state.
*
* @see ClipsIndexAction
* @see ClipsTimeAction
* @see ClipsValueAction
* @see ClipValuesAction
*/
		public function get targets():Array
		{
			return null;
		}
/**
* Boolean true if action is in done state.
*/
		public function get done():Boolean
		{
			return _done;
		}
		public var data:Object;
		public var items:Array;
		protected function _redo():void
		{ }
		protected function _undo():void
		{ }
		protected var _done:Boolean = false;
		private function __push():void
		{
			if (currentDo < doStack.length - 1) 
			{
				doStack.splice(currentDo + 1, doStack.length - (currentDo + 1));
			}
			doStack.push(this);
			redo();
		}
	}
}