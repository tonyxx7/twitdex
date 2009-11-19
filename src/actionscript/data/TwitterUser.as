﻿package actionscript.data
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	
		 * The user's latest status
		 */
		public var status:TwitterStatus;
		
		/**
		 * A list of the user's statuses
		 */
		[Bindable]
		public var statuses:ArrayCollection;
		
		[Bindable]
		public var isDead:Boolean;
		
		public var hasBeenInit:Boolean;
		
		private var loader:Loader;
		private var request:URLRequest;
		public var userBitmapData:BitmapData;
				
		function TwitterUser(user:Object) {
				statuses = new ArrayCollection();
				hasBeenInit = true;
				isDead = false;
				
			}
		
		public function startBitmapLoad():void
		{
			loader = new Loader();
			request = new URLRequest(profileImageUrl);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loadCompleted);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,loadError);
			loader.load(request);
		}
		private function loadCompleted(e:Event):void {
			userBitmapData = Bitmap(loader.content).bitmapData;
			dispatchEvent(new Event("bitmapLoaded"));
		}
		
		private function loadError(e:IOErrorEvent):void {
			userBitmapData = null;
			dispatchEvent(new Event("bitmapLoaded"));
		}
	}