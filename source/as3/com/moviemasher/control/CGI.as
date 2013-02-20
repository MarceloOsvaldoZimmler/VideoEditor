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
package com.moviemasher.control
{
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	import s3.flash.*;

/**
* Implimentation class represents a control for interacting with CGI scripts
*/
	public class CGI extends Text
	{
		public function CGI()
		{
			_defaults.id = '';
			_defaults[CGIProperty.UPLOADNAME] = 'Filedata';
			_defaults[CGIProperty.DOWNLOADNAME] = 'mash.mp4';
			_defaults['clickstatus'] = '';
			
			_allowFlexibility = false;
			__fileTypes = new Object();
			__transfers = new Vector.<CGITransfer>();
		}
		override public function initialize():void 
		{
			super.initialize();
			__cgiStop();
			var n:Number = super.getValue(CGIProperty.PROGRESS).number;
			if (n) __cgiSetProgress(n);
			if (getValue(CGIProperty.AUTOLOAD).boolean) 
			{
				// reads control tag for relavent attributes
				__sessionInit();
				// only process tasks that aren't file related
				__processTasks(); 
			}
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			switch (property)
			{
				case CGIProperty.PROGRESS:
					value = new Value(__progress ? __progress:Value.UNDEFINED);
					break;
				case CGIProperty.STATUS:
					value = new Value(__status.length ? __status : null);
					break;
				case 'filename':
					value = new Value(((__transfer == null) ? '' : __transfer.name));
					break;
				case 'filetype':
					value = new Value(((__transfer == null) ? '' : __typeFromName(__transfer.name)));
					break;
				case 'queued':
					value = new Value(__transfers.length);
					break;
				case 'filesize':
					value = new Value(((__transfer == null) ? '' : __transfer.size));
					break;
				case 'month':
				case 'monthUTC':
					value = new Value(StringUtility.strPad(1 + (new Date())[property], 2));					
					break;
				case 'date':
				case 'dateUTC':
				case 'hours':
				case 'hoursUTC':
				case 'seconds':
				case 'secondsUTC':
				case 'minutes':
				case 'minutesUTC':
					value = new Value(StringUtility.strPad((new Date())[property], 2));					
					break;
				case 'fullYear':
				case 'fullYearUTC':
				case 'time':
					value = new Value((new Date())[property]);
					break;
				default:
					if (__sessionHasKey(property))
					{
						value = new Value(__cgiSession[property]);
					}
					else
					{
						value = super.getValue(property);
					}
			}
			return value;
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			
			switch(property)
			{
				case CGIProperty.PROGRESS:
					break;
				case CGIProperty.STATUS:
					value = new Value();
				default: 
					//RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' ' + value.string + ' ' + __settingValue);
					if (! __settingValue)
					{
						__settingValue = true;
						super.setValue(value, property);
						_dispatchEvent(property, value);
						__settingValue = false;
					}
			}
			return false;
		}
		final protected function _cgiSetStatus(s:String):void
		{
			__status = s;
			_dispatchEvent(CGIProperty.STATUS);
		}
		override protected function _createChildren():void
		{
			super._createChildren();
			var filetype_list:XMLList = _tag.filetype;
			var z:int = filetype_list.length();
			__fileFilters = new Array();
			var file_type:XML;
			var extension,mime:String;
			var extensions,mimes:Array;
			var j,y:int;
			for (var i:int = 0; i < z; i++)
			{
				file_type = filetype_list[i];
				extension = String(file_type.@extension);
				if (extension.length)
				{
					__fileFilters.push(new FileFilter(String(file_type.@description), extension));
					mime = String(file_type.@mime);
					if (mime.length)
					{
						mimes = mime.split(';');
						extensions = extension.split(';');
						y = extensions.length;
						for (j = 0; j < y; j++)
						{
							extension = extensions[j].substr(2); // remove '*.' prefix
							if (j < mimes.length) mime = mimes[j];
							__fileTypes[extension] = mime;
							
						}
					}
				}
			}
		}
 		override protected function _release():void
		{
			try
			{
				if (! (_disabled || __fileDialogIsOpen))
				{
					
					
					if (! (super.getValue(CGIProperty.UPLOAD).empty && super.getValue(CGIProperty.CHOOSE).empty))
					{
						if (super.getValue(CGIProperty.BYTES).empty)
						{
							// upload or choose file
							__fileReferenceList = new FileReferenceList();
							__fileReferenceList.addEventListener(Event.CANCEL, __errorCancelList);
							__fileReferenceList.addEventListener(Event.SELECT, __completeSelectList);
							__fileDialogIsOpen = true;
							if (__fileFilters.length) __fileReferenceList.browse(__fileFilters);
							else __fileReferenceList.browse();
						}
						else
						{
							// gather bytes arrays
							// create CGITransfer for each one
							
							var bytes_string:String = super.getValue(CGIProperty.BYTES).string;
							var delimiter:String = RunClass.MovieMasher['getOption']('parse', 'evaluate_delimiter');
							var vector:Vector.<IValued> = new Vector.<IValued>();
							var expressions:Array = bytes_string.split(delimiter);
							var i,z,j,y:uint;
							var object:Object;
							var ivalued:IValued;
							var array:Array;
							var transfer:CGITransfer;
							z = expressions.length;
							var bytes:TransferBytes;
							for (i = 0; i < z; i++)
							{
								//RunClass.MovieMasher['msg']('getting ' + expressions[i]);
								object = RunClass.MovieMasher['getByID'](expressions[i]);
								if (object is IValued)
								{
									ivalued = object as IValued;
									object = ivalued.getValue('transfers').object;
									if (object is Array)
									{
										array = object as Array;
										y = array.length;
										//RunClass.MovieMasher['msg']('got transfers ' + y);
								
										for (j = 0; j < y; j++)
										{
											object = array[j];
											if (object is TransferBytes)
											{
												bytes = object as TransferBytes;
												transfer = new CGITransfer();
												transfer.bytes = bytes.bytes;
												transfer.name = bytes.name;
												__transfers.push(transfer);
											}
										}
									}
								}
							}
							__sessionInitTransfer();
						}
					}
					else
					{
						__sessionInit();
						if (__sessionHasKey(CGIProperty.DOWNLOAD)) 
						{
							// download file
							__fileReference = new FileReference();
							__addListeners(__fileReference, false);
							var url_string:String = __cgiSession[CGIProperty.DOWNLOAD]
							url_string = RunClass.ParseUtility['brackets'](url_string);
							
							var url:Object = new RunClass.URL(url_string);
							__fileDialogIsOpen = true;
						
							var file_name:String = __cgiSession[CGIProperty.DOWNLOADNAME];
							var dot_index:int = file_name.indexOf('.');
							
							if ((dot_index == -1) || (file_name.substr(dot_index).indexOf(' ') != -1))
							{
								file_name = '';
							}
							__fileReference.download(new URLRequest(url.absoluteURL), file_name);
							__cgiSetProgress(1);
						}
						else __processTasks();
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._release', e);
			}
		}
        private function __addListeners(dispatcher:IEventDispatcher, uploading:Boolean = false):void 
		{
            dispatcher.addEventListener(IOErrorEvent.IO_ERROR, __errorIO);			
            dispatcher.addEventListener(ProgressEvent.PROGRESS, __progressTransfer);
            dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, __errorSecurity);
            if (uploading)
			{
            	dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, __errorHTTP);
              	dispatcher.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA,__completeUpload);
			}
			else
			{
			 	dispatcher.addEventListener(Event.CANCEL, __errorCancel);
           		dispatcher.addEventListener(Event.COMPLETE, __completeDownload);
			}
        }
		
		private function __cgiRequestClear()
		{
			
			if (__sessionHasKey(CGIProperty.UPLOAD)) // just uploaded file
			{
				__cgiSession[CGIProperty.UPLOAD] = '';
			}
			else if (__sessionHasKey(CGIProperty.URL))
			{
				__cgiSession[CGIProperty.URL] = '';
				if (__sessionHasKey(CGIProperty.MEDIA)) __cgiSession[CGIProperty.MEDIA] = '';
				if (__sessionHasKey(CGIProperty.MASH) && (__mash != null)) 
				{
					__cgiSession[CGIProperty.MASH] = '';
				}
			}
		}
		private function __cgiSetProgress(n:Number):void
		{
			__progress = n;
			_dispatchEvent(CGIProperty.PROGRESS);
		}
		private function __cgiStop(error:String = '')
		{
			try
			{
				//RunClass.MovieMasher['msg'](this + '.__cgiStop');
				__cgiSession = null;
				__cgiSessionBackup = null;
				__transfer = null;
				__fileReference = null;
				_cgiSetStatus(error);
				__cgiSetProgress(0);
				__sessionInitTransfer();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__cgiStop', e);
			}
		}
		private function __cgiUploadTransfer():void
		{
			var s:String;
			var url:Object;
			var defined:Boolean = (__transfer != null);
			try
			{
				if (defined) defined = __sessionHasKey(CGIProperty.UPLOAD);
				if (defined)
				{
					s = __cgiSession[CGIProperty.UPLOAD];
					s = RunClass.ParseUtility['brackets'](s, null, true);
					defined = (s.length > 0)
				}
				if (defined)
				{
					url = new RunClass.URL(s);
					if (__transfer.isFile)
					{
						__fileReference = __transfer.fileReference;
						__addListeners(__fileReference, true);
						__fileReference.upload(new URLRequest(url.absoluteURL), getValue(CGIProperty.UPLOADNAME).string);
					}
					else
					{
						// TODO: construct data fetcher with bytes!
					}
					__cgiSetProgress(1);
				}
				else
				{
					__cgiStop();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__cgiUploadTransfer', e);
			}
		}
		private function __completeDownload(event:Event):void
		{
			// only called for downloads, when finished transferring
			try
			{
				__fileDialogIsOpen = false;
				__cgiSetProgress(100);
				__removeListeners(__fileReference, false);
				__fileReference = null;
				__cgiSession[CGIProperty.DOWNLOAD] = '';
				__processTasks();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__completeDownload', e);
			}
		}
		private function __completeUpload(event:DataEvent):void
		{
			
			var is_s3:Boolean = (event.target == __s3Fetcher);
			if (is_s3)
			{
				__s3Fetcher.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, __completeUpload);
				__s3Fetcher.removeEventListener(IOErrorEvent.IO_ERROR, __errorIO);
	
				__s3Fetcher.removeEventListener(ProgressEvent.PROGRESS, __progressTransfer);
				__s3Fetcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, __errorSecurity);
				__s3Fetcher = null;
			}
			if (__fileReference != null) 
			{
				__removeListeners(__fileReference, true);
				__fileReference = null;
			}
			// only sent for uploads, when finished transferring
			var xml:XML = null;
			try
			{
				if ((event.data != null) && event.data.length) xml = new XML(event.data);
				__cgiSetProgress(100);
				__xmlLoaded(xml, is_s3);				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__completeUpload ' + (xml == null), e);
			}
		}
		private function __completeURL(event:Event):void
		{
			try
			{
				//RunClass.MovieMasher['msg'](this + '.__completeURL ' + event);
				if (__dataFetcher != null)
				{
				
					var xml_object:XML = __dataFetcher.xmlObject();
					var data:String;
					if (xml_object == null)
					{
						data = __dataFetcher.data();
						if (data && data.length) _cgiSetStatus('Could not parse response');
					}
					__dataFetcher.removeEventListener(Event.COMPLETE, __completeURL);
					__dataFetcher = null;
					if (xml_object != null) __xmlLoaded(xml_object);
					else 
					{
						_cgiSetStatus('Got no response, will retry')
						if (__cgiSessionBackup != null)
						{
							//RunClass.MovieMasher['msg'](this + '.__completeURL setting __cgiSession = __cgiSessionBackup');
							
							__cgiSession = __cgiSessionBackup;
						}
						//RunClass.MovieMasher['msg'](this + '.__completeURL __processURL');
						__processURL();
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__completeURL', e);
			}
		}
		private function __completeSelectList(event:Event):void
		{
			try
			{
				var i,z:int;
				var transfer:CGITransfer;
				z = __fileReferenceList.fileList.length;
				for (i = 0; i < z; i++)
				{
					transfer = new CGITransfer();
					transfer.fileReference = __fileReferenceList.fileList[i];
					
					__transfers.push(transfer);
				}
				__errorCancelList(null);
				__sessionInitTransfer();				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__completeSelectList', e);
			}
		}
		private function __doDelay(delay_secs:Number):Boolean
		{
			var do_delay:Boolean = ((! isNaN(delay_secs)) && delay_secs);
			if (do_delay)
			{
				if (__requestTimer == null)
				{
					__requestTimer = new Timer(1000 * delay_secs, 1);
					__requestTimer.addEventListener(TimerEvent.TIMER, __timerRequest);
					__requestTimer.start();
				}
			}
			return do_delay;
		}
		private function __errorCancel(event:Event):void
		{
			try
			{
				__fileDialogIsOpen = false;
				__cgiStop();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __errorCancelList(event:Event):void
		{
			__fileDialogIsOpen = false;
			if (__fileReferenceList != null)
			{
				__fileReferenceList.removeEventListener(Event.CANCEL, __errorCancelList);
				__fileReferenceList.removeEventListener(Event.SELECT, __completeSelectList);
				__fileReferenceList = null;
			}
		}
		private function __errorHTTP(event:HTTPStatusEvent):void
		{
			try
			{
				//RunClass.MovieMasher['msg'](this + '.__errorHTTP ' + event);
				if (event.status >= 300) __cgiStop(String(event));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __errorIO(event:Event):void
		{
			//RunClass.MovieMasher['msg'](this + '.__errorIO ' + event);
			
			try
			{
				__cgiStop('IO Error');
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __errorSecurity(event:SecurityErrorEvent):void
		{
			//RunClass.MovieMasher['msg'](this + '.__errorSecurity ' + event);
			
			try
			{
				__cgiStop('Security Error');
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __processGet():Boolean
		{
			var s:String;
			var url:Object;
			var defined:Boolean = __sessionHasKey(CGIProperty.GET);
			if (defined)
			{
				s = __cgiSession[CGIProperty.GET];
				__cgiSession[CGIProperty.GET] = '';
				s = RunClass.ParseUtility['brackets'](s, null, true);
				defined = (s.length > 0)
			}
			if (defined)
			{
				url = new RunClass.URL(s);
				s = '_self';
				if (__sessionHasKey(CGIProperty.TARGET)) 
				{
					s = __cgiSession[CGIProperty.TARGET];
					__cgiSession[CGIProperty.TARGET] = '';
				}
			//	RunClass.MovieMasher['msg'](this + '.__processGet ' + url.absoluteURL + ' ' + s);
				navigateToURL(new URLRequest(url.absoluteURL), s);
			}
			return defined;
		}
		private function __processTasks(dont_url:Boolean = false):void
		{
			try
			{
				__processGet();
				__processTrigger();
				if (dont_url || (! __processURL())) __cgiStop();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__processTasks', e);
			}
		}
		private function __processTrigger():Boolean
		{
			var s:String;
			var defined:Boolean = __sessionHasKey(CGIProperty.TRIGGER);
			if (defined)
			{
				s = __cgiSession[CGIProperty.TRIGGER];
				__cgiSession[CGIProperty.TRIGGER] = '';
				RunClass.MovieMasher['evaluate'](s);
			}
			return defined;
		}
		private function __processURL():Boolean
		{
			//RunClass.MovieMasher['msg'](this + '.__processURL ' + __cgiSession[CGIProperty.DELAY] + ' ' + __cgiSession[CGIProperty.URL]);
			 
			var defined:Boolean = __sessionHasKey(CGIProperty.URL);
			if (defined)
			{
				if (! __doDelay(__cgiSession[CGIProperty.DELAY])) __requestURL();
			}
			return defined;
		}
		private function __progressTransfer(event:ProgressEvent):void
		{
			try
			{
				__fileDialogIsOpen = false;
				//_cgiSetStatus('Transfering');
				if (event.bytesTotal)
				{
					__cgiSetProgress(Math.round((event.bytesLoaded * 100) / event.bytesTotal));
				}	
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__progressTransfer', e);
			}
		}
		private function __removeListeners(dispatcher:IEventDispatcher, uploading:Boolean = false):void 
		{
            dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, __errorIO);
            dispatcher.removeEventListener(ProgressEvent.PROGRESS, __progressTransfer);
            dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, __errorSecurity);
            if (uploading)
			{
           		dispatcher.removeEventListener(HTTPStatusEvent.HTTP_STATUS, __errorHTTP);
            	dispatcher.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA,__completeUpload);
			}
			else
			{
				dispatcher.removeEventListener(Event.CANCEL, __errorCancel);
           		dispatcher.removeEventListener(Event.COMPLETE, __completeDownload);
			}
        }
        private var __cgiSessionBackup:Object;
        
		private function __requestURL(url_string:String = null):void
		{
			if (url_string == null) url_string = __cgiSession[CGIProperty.URL];
			var key:String;
			__cgiSessionBackup = new Object();
			for (key in __cgiSession)
			{
				__cgiSessionBackup[key] = __cgiSession[key];
			}
			__cgiSessionBackup.delay = 10;
			
			var url:String;
			var result:String;
			var object:Object;
			var node,container:XML = null;
			var session_has_mash:Boolean = __sessionHasKey(CGIProperty.MASH);
			var session_has_media:Boolean = __sessionHasKey(CGIProperty.MEDIA);
			var xml_type:String;
			try
			{
				if ((url_string != null) && url_string.length)
				{	
					if (session_has_mash)
					{
						object = RunClass.MovieMasher['getByID'](__cgiSession[CGIProperty.MASH]);
						__mash = (object is IMash ? object as IMash : null);
						__cgiSession[CGIProperty.MASH] = '';
					}
					url = RunClass.ParseUtility['brackets'](url_string, null, true);
					__cgiSessionBackup[CGIProperty.URL] = url;
					if ((session_has_media || session_has_mash) )
					{
						node = <moviemasher />;
						if (__mash != null)
						{
							if (session_has_media && session_has_mash) xml_type = 'fatxml';
							else if (session_has_mash) xml_type =  ClipProperty.XML;
							else xml_type = ClipProperty.MEDIA;
							container = __mash.getValue(xml_type).object as XML;
							if (xml_type == ClipProperty.MEDIA) node = container;
							else node.setChildren(container);
						}
					}
					if (url.substr(0, 6) == 'parent')
					{
						result = RunClass.MovieMasher['evaluate'](url);
						try
						{
							node = new XML(result);
							__xmlLoaded(node);
						}
						catch(e:*)
						{
							RunClass.MovieMasher['msg'](this + '.__requestURL ' + url + ' ' + result);
						}
					}
					else
					{
						__dataFetcher = RunClass.MovieMasher['dataFetcher'](url, node);
						//RunClass.MovieMasher['msg'](this + '.__requestURL ' + url + ' ' + __dataFetcher);
						__dataFetcher.retries = 0;
						__dataFetcher.addEventListener(Event.COMPLETE, __completeURL);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__requestURL ' + url_string + " " + url, e);
			}
		}
		private function __sessionHasKey(key:String):Boolean
		{
			
			var has_key:Boolean = false;
			if ((__cgiSession != null) && (__cgiSession[key] != null))
			{
				if (String(__cgiSession[key]).length)
				{
					has_key = true;
				}
			}
			return has_key;
		}
		private function __sessionInit():void
		{
			try
			{
				if (__cgiSession == null)
				{
					//RunClass.MovieMasher['msg'](this + '.__sessionInit');
					__cgiSession = XMLUtility.attributeData(_tag);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__sessionInit', e);
			}
		}
		private function __sessionInitTransfer():void
		{
			try
			{
				if ((__transfer == null) && (__transfers.length > 0))
				{
					__sessionInit();
					var transfer:CGITransfer = __transfers.shift();
					__transfer = transfer;
					__fileReference = __transfer.fileReference;
					
					var choose:String = super.getValue(CGIProperty.CHOOSE).string;
					if (choose.length) __requestURL(choose);
					else __cgiUploadTransfer(); // will call __cgiStop if session has no upload key
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__sessionInitTransfer', e);
			}
		}
		private function __timerRequest(event:TimerEvent):void
		{
			if (__requestTimer != null) 
			{
				__requestTimer.stop();
				__requestTimer.removeEventListener(TimerEvent.TIMER, __timerRequest);
				__requestTimer = null;
			}
			__requestURL();
		}
		private function __typeFromName(name:String):String
		{
			var type:String = '';
			var pos:int = name.lastIndexOf('.');
			var extension:String = '';
			if (pos != -1) extension = name.substr(pos + 1);
			if (extension.length)
			{
				extension = extension.toLowerCase();
				if (__fileTypes[extension] != null) type = __fileTypes[extension];
			}
			return type;
		}
		private function __xmlLoaded(xml:XML, dont_clear:Boolean = false):void
		{
			try
			{
				__cgiSessionBackup = null;
				//RunClass.MovieMasher['msg'](this + '.__xmlLoaded ' + dont_clear + ' ' + ((xml == null) ? 'null' : xml.toXMLString() + ' ' + __cgiSession));
				if (! dont_clear) __cgiRequestClear();
				
				if (xml != null) __cgiSession = XMLUtility.attributeData(xml, __cgiSession);
			
				if (__cgiSession[CGIProperty.PROGRESS] == -1) __cgiStop(__cgiSession[CGIProperty.STATUS]);
				else
				{
					
					if (__sessionHasKey(CGIProperty.STATUS)) 
					{
						_cgiSetStatus(__cgiSession[CGIProperty.STATUS]);
						__cgiSession[CGIProperty.STATUS] = '';
					}
					if (__sessionHasKey(CGIProperty.PROGRESS))
					{
						__cgiSetProgress(__cgiSession[CGIProperty.PROGRESS]);
						__cgiSession[CGIProperty.PROGRESS] = '0';
					}
				
					__cgiSession[CGIProperty.CHOOSE] = '';
					var bucket:String = '';
					var key:String = '';
					var keyid:String = '';
					if (xml != null)
					{
						key = String(xml.@['key']);
						keyid = String(xml.@['keyid']);
						bucket = String(xml.@['bucket']);
					}
					if (bucket.length && key.length && keyid.length)
					{
						try
						{
							var token:String = String(xml.@['token']);
							var region:String = String(xml.@['region']);
							var acl:String = String(xml.@['acl']);
							var policy:String = String(xml.@['policy']);
							var signature:String = String(xml.@['signature']);
							var mime:String = String(xml.@['mime']);
							var secure:String = String(xml.@['secure']);
							var options:S3PostOptions = new S3PostOptions()
							if (acl.length) options.acl = acl;
	
							if (mime.length) options.contentType = mime;
							if (policy.length) options.policy = policy;
							if (token.length) options.securityToken = token;
							if (region.length) options.region = region;
							if (signature.length) options.signature = signature;
							options.secure = (secure == '1');
							
							
							__s3Fetcher = new S3PostRequest(keyid, bucket, key, options);
							__s3Fetcher.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, __completeUpload);
							__s3Fetcher.addEventListener(IOErrorEvent.IO_ERROR, __errorIO);
							__s3Fetcher.addEventListener(ProgressEvent.PROGRESS, __progressTransfer);
							__s3Fetcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, __errorSecurity);
				
							//__s3Fetcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, __errorHTTP);
							if ((__transfer != null) && (__transfer.fileReference == null)) __s3Fetcher.transfer(__transfer.bytes, __transfer.name);
							else __s3Fetcher.upload(__transfer.fileReference);
						}
						catch(e:*)
						{
							RunClass.MovieMasher['msg'](this + '.__xmlLoaded S3', e);
						}
					}
					else if (__sessionHasKey(CGIProperty.UPLOAD)) __cgiUploadTransfer(); // will call __cgiStop if session has no upload key
					else
					{
						var trigger_url:Boolean = true;
						try
						{
							if (__sessionHasKey(CGIProperty.DOWNLOAD)) trigger_url = false;
							else if (__sessionHasKey(CGIProperty.DELAY) && (__cgiSession[CGIProperty.DELAY] < 0) ) trigger_url = false;
							__processTasks(! trigger_url);
						}
						catch(e:*)
						{
							RunClass.MovieMasher['msg'](this + '.__xmlLoaded trigger ' + trigger_url, e);
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__xmlLoaded', e);
			}
		}
		private var __cgiSession:Object;
		private var __dataFetcher:IDataFetcher;
		private var __fileDialogIsOpen:Boolean = false;
		private var __fileFilters:Array;
		private var __fileReference:FileReference;
		private var __fileReferenceList:FileReferenceList;
		private var __transfer:CGITransfer;
		private var __transfers:Vector.<CGITransfer>;
		private var __fileTypes:Object;
		private var __mash:IMash;
		private var __progress:Number = 0;
		private var __requestTimer:Timer;
		private var __s3Fetcher:S3PostRequest;
		private var __settingValue:Boolean = false;
		private var __status:String = '';
	}
}

import flash.utils.*;
import flash.net.*;

class CGITransfer extends Object
{
	public function set fileReference(file_reference:FileReference):void
	{
		_fileReference = file_reference;
		isFile = true;
	}
	public function get fileReference():FileReference
	{
		return _fileReference;
	}
	public function get size():Number
	{
		return isFile ? _fileReference.size : bytes.length;
	}
	public function get name():String
	{
		return (_name.length ? _name : (isFile ? _fileReference.name : ''));
	}
	public function set name(string:String):void
	{
		_name = string;
	}
	public var isFile:Boolean;
	public var url:String;
	public var bytes:ByteArray;
	protected var _fileReference:FileReference;
	protected var _name:String = '';
}
