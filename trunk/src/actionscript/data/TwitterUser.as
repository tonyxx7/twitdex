package actionscript.data
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
		/**		* Object that contains information about a Twitter user		*/	public class TwitterUser extends EventDispatcher{		/**		* ID of the Twitter user		*/		public var id:Number;		/**		* String containing the name of the Twitter status 		*/		public var name:String;		/**		* String containing the name of the Twitter user		*/		public var screenName:String;		/**		* String containing the geographic location of the Twitter user		*/		public var location:String;		/**		* String containing a description of the Twitter user		*/		public var description:String;		/**		* String containing the URL to the Twitter user's profile image		*/		public var profileImageUrl:String;		/**		* String containing the URL to the Twitter user's home page, blog, etc.		*/		public var url:String;				public var isProtected:String;				public var friendsCount:Number;				public var followersCount:Number;				public var createdAt:String;				public var favouritesCount:String;				public var utcOffset:String;				public var timeZone:String;				public var following:String;				public var notifications:String;				public var statusesCount:String;				/**
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
				
		function TwitterUser(user:Object) {			if (user!=null){				id = user.id;				name = user.name;				screenName = user.screen_name;				location = user.location;				description = user.description;				profileImageUrl = user.profile_image_url;				url = user.url;				followersCount = user.followers_count;				friendsCount = user.friends_count;				createdAt = user.created_at;				isProtected = user.protected;				favouritesCount = user.favourites_count;				utcOffset = user.utc_offset;				timeZone = user.time_zone;				following = user.following;				notifications = user.notifications;				statusesCount = user.statuses_count;
				statuses = new ArrayCollection();
				hasBeenInit = true;
				isDead = false;
								if (user.status!=null && user.status.text!=null && user.status.text!="")				{					try{						this.status = new TwitterStatus(user.status,this);					} catch (e:Error){						this.status = null;					}				}
			}		}
		
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
	}}