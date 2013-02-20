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

package com.moviemasher.events
{
	import flash.events.*;
	import com.moviemasher.action.*;
	
/**
* Class represents a change in an {@link Action} queue
*
* @see Action
* @see Timeline
* @see Mash
*/
	public class ActionEvent extends Event
	{
		public static const ACTION : String = 'action';
		public var action : Action;
		private var __isUndoing:Boolean;
		public function ActionEvent(iAction:Action = null, iUndoing:Boolean=false)
		{
			super(ActionEvent.ACTION);
			action = iAction;
			__isUndoing = iUndoing;
		}
		public function get redoing():Boolean
		{
			return ! __isUndoing;
		}
		
		public function get undoing():Boolean
		{
			return __isUndoing;
		}
	}
}