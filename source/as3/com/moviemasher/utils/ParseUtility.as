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

package com.moviemasher.utils
{
	import bkde.as3.parsers.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;

/**
* Static class handles parsing of patterned string potentially containing {@link IValued} property references
*
* @see CGI
* @see Text
* @see Increment
* @see Source
*/

	public class ParseUtility
	{
		
		public static function booleanExpressions(expressions:String, hash:* = null):Boolean
		{
			var i,z:uint;
			var a:Array;
			var and_search,should:Boolean = false;
			try
			{
				if ((expressions != null) && expressions.length)
				{
					and_search = (expressions.indexOf('|') == -1);
					a = expressions.split((and_search ? '&' : '|'));

					z = a.length;
					for (i = 0; i < z; i++)
					{
						should = booleanExpression(a[i], hash);
						if (should && (! and_search))
						{
							break;
						}
						if ((! should) && and_search)
						{
							break;
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('ParseUtility.booleanExpressions ' + expressions + ' ' + i, e);
			}
			return should;
		}
		public static function booleanExpression(string:String, hash:* = null):Boolean
		{
			var elements:Array = new Array();
			var property:String = '';
			var value:Value = null;
			
			var ok = false;
			try
			{
				if (string.length)
				{
					elements = string.split(/([\w\.]+)([><!]?[=]?)(.+)/g);
					var z:uint = elements.length;
					//RunClass.MovieMasher['msg']('ParseUtility.booleanExpression ' + elements.join('|'));
					if (z == 5)
					{
						var bits:Array = elements[1].split('.');
						var test_value:String;
						var is_undefined:Boolean = true;
						var gotten:*;
						var ob:IValued = null;
						var left_side:String;	
						var xml:XML;
						var n:Number = NaN;
			
						var attribute:XML;
						test_value = elements[3];
						//RunClass.MovieMasher['msg']('ParseUtility.booleanExpression ' + bits.join(".") + ' = ' + test_value + ' ' + string);
						var test_empty:Boolean = ( (test_value == 'undefined') || (test_value == 'null')  || (test_value == 'empty') );
						if (bits.length > 1)
						{
							property = bits.pop();
							if (property.length)
							{
								try
								{
									gotten = RunClass.MovieMasher['getByID'](bits.join('.'));
									if (gotten != null)
									{
										if (gotten is IValued)
										{
											ob = gotten as IValued;
											value = ob.getValue(property);
										
											if (test_empty) is_undefined = value[((test_value == 'empty') ? 'empty' : 'undefined')];
											left_side = value.string;
										}
										else if (gotten is XML)
										{
											xml = gotten as XML;
											left_side = xml.@[property];
											
											if (test_empty)
											{
												if (test_value == 'empty') is_undefined = ! left_side.length;
												else 
												{
													is_undefined = true;
													for each(attribute in xml.@*)
													{
														if (attribute.name() == property)
														{
															is_undefined = false;
															break;
														}
													}
												}
											}
										}
										else if (gotten is String)
										{
											left_side = gotten as String;
											if (left_side[property] != null)
											{
												if (left_side[property] is Function)
												{
													left_side = left_side[property]();
												}
												else left_side = left_side[property];
												if (test_empty) is_undefined = ! left_side.length;
											}
										}
										else if (gotten is Object)
										{
											left_side = gotten[property];
											if (test_empty) is_undefined = ! left_side.length;
										}
									}
								}
								catch(e:*)
								{
									RunClass.MovieMasher['msg']('ParseUtility.booleanExpression ob = ' + bits.join('.'), e);
								}
								if (test_empty)
								{
									switch (elements[2])
									{
										case '=' :
											ok = is_undefined;
											break;
										case '!=' :
										case '>' :
										case '>=' :
											ok = ! is_undefined;
											break;
									}
								}
								else
								{
									if (test_value.indexOf('{') != -1) 
									{
										n = expression(test_value, hash, true);
										if (isNaN(n)) test_value = brackets(test_value, hash, true);
										else test_value = String(n);
									}
										
									switch (elements[2])
									{
										case '>' :
											ok = (Number(left_side) > Number(test_value));
											break;
										case '>=' :
											ok = (Number(left_side) >= Number(test_value));
											break;
										case '<' :
											ok = (Number(left_side) < Number(test_value));
											break;
										case '<=' :
											ok = (Number(left_side) <= Number(test_value));
											break;
										case '!=' :
											ok = (left_side != test_value);
											break;
										case '=' :
											ok = (left_side == test_value);
											break;
									}
								}
							}
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('ParseUtility.booleanExpression ' + string + ' ' + elements + ' ' + property, e);
			}
			return ok;
		}
		public static function bracketed(pat, include_indices:Boolean = false):Array
		{
			var a:Array = new Array();
			try
			{
				var left_brace:Number = pat.indexOf('{');
				var right_brace:Number = 0;
				var field:String;
				while (left_brace != -1)
				{
					
					right_brace = pat.indexOf('}', left_brace);
					if (right_brace == -1) break;
					field = pat.substr(left_brace + 1, right_brace - (left_brace + 1))
					if (include_indices) a.push(new Array(left_brace + 1, field));
					else a.push(field);
					left_brace = pat.indexOf('{', right_brace);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('ParseUtility.brackets caught ' + e);
			}
				
			return a;
		}
		public static function optionBrackets(string:String):String
		{
			try
			{
				var position:Number = string.indexOf('{');
				var options:Array = new Array();
				var next_position:Number;
				var dot_string:String;
				var dots:Array;
				var option_string:String;
				if (position > -1)
				{
					next_position = -1;
					while (position > -1)
					{
						dot_string = string.substr(next_position + 1, (position - (next_position + 1)));
						if (dot_string.length)
						{
							options.push(dot_string);
						}
						next_position = string.indexOf('}', position);
						dot_string = string.substr(position + 1, next_position - (1 + position));
						dots = dot_string.split('.');
						option_string = '';
						if (dots.length > 1) option_string = RunClass.MovieMasher['getOption'](dots[0], dots[1]);
						else if (dots.length) option_string = RunClass.MovieMasher['getParameter'](dots[0]);
						if (option_string.length) dot_string = option_string;
						else dot_string =  '{' + dot_string + '}';
						
						options.push(dot_string);
						position = string.indexOf('{', next_position);
					}
					dot_string = string.substr(next_position + 1);
					if (dot_string.length)
					{
						options.push(dot_string);
					}
					string = options.join('');
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('ParseUtility.optionBrackets caught ' + e);
			}
				
			return string;
		}
		public static function brackets(pat:String, hash:* = null, options:Boolean = false):String
		{
			if (hash == null) hash = RunClass.MovieMasher['objects'];
			var a:Array;
			a = bracketed(pat, true);
			var y, j, z, i, index:int;
			var reference:String;
			var s:String = '';
			var last_index:int = 0;
			var dots:Array;
			var target:*;
			var key:String;
			var value:Value;
			try
			{				
				y = a.length;
				if (y)
				{
					for (j = 0; j < y; j++)
					{
						index = a[j][0];
						reference = a[j][1];
						if ((index - 1) > last_index)
						{
							s += pat.substr(last_index, (index - 1) - last_index);
						}
						last_index = index + reference.length + 1;					
						dots = reference.split('.');
						z = dots.length;
						
						target = hash;
						for (i = 0; i < z; i++)
						{
							key = dots[i];
							if (target is IValued)
							{
								try
								{
									value = target.getValue(key);
									if (value.undefined) target = '';
									else target = value.object;
								}
								catch(e:*)
								{
									RunClass.MovieMasher['msg']('ParseUtility.brackets IValued caught ' + e + ' ' + target + '.' + key);
								}
							}
							else if (target is XML)
							{
								if (target[key] is Function) target = target[key]();
								else target = String(target.@[key]);
							}
							else if (target[key] == null)
							{
								target = '{' + reference + '}';
								break;
							}
							else 
							{
								try
								{
									if (target[key] is Function) target = target[key]();
									else target = target[key];
								}
								catch(e:*)
								{
									target = '{' + reference + '}';
									//RunClass.MovieMasher['msg']('ParseUtility.brackets setter caught ' + e + ' ' + reference + ' ' + target + '.' + key);
								}
							}
						}
						if (target is XML) target = (target as XML).toXMLString();
						s += String(target);
					}
				}
				if (last_index < pat.length)
				{
					s += pat.substr(last_index);
				}
				if (options && (s.indexOf('{') != -1))
				{
					s = ParseUtility.optionBrackets(s);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('ParseUtility.brackets caught ' + e + ' ' + pat + ' ' + target + '.' + key);
			}
			return s;
		}
		public static function expression(pat:String, hash:* = null, options:Boolean = false):Number
		{
			var n:Number = NaN;
			pat = ParseUtility.brackets(pat, hash, options); 
			var mpVal:MathParser = new MathParser([]);
			var compobjVal:CompiledObject = new CompiledObject();
			compobjVal = mpVal.doCompile(pat);	
			if (compobjVal.errorStatus != 1) 
			{
				n = mpVal.doEval(compobjVal.PolishArray, []);
			}
			return n;
		}
	}
}
