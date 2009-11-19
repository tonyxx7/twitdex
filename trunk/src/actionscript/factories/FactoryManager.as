package actionscript.factories
{
	import actionscript.data.TwitterSearch;
	import actionscript.data.TwitterStatus;
	import actionscript.data.TwitterUser;
	import actionscript.events.TwitterEngineEvent;
	import actionscript.events.TwitterEvent;
	import actionscript.twitterconnection.TwitterConnector;
	
	import de.polygonal.ds.HashTable;
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	
	public class FactoryManager extends EventDispatcher
	{
		private static var _instanceOfTwitterEngine:FactoryManager = new FactoryManager();
		private var twitter:TwitterConnector;
		
		// information lists
		public var userHash:HashTable;
		private var _userList:ArrayCollection;
		public var favorites:ArrayCollection;
		public var messages:ArrayCollection;
		
		// timer
		private var tweetBeat:Timer;
		
		// tracking varables
		private var lastStatusId:Number;
		private var lastMessageId:Number;
		private var switchIndex:int;
		
		public function get userList():ArrayCollection{return _userList}
		
		private var _user:TwitterUser;
		public function get user():TwitterUser{return _user}
		
        public function FactoryManager()
        {
            if (_instanceOfTwitterEngine != null){
                throw new Error("TwitterEngine is a Singleton and can only be accessed through TwitterEngine.instanceOfTwitterEngine");
            }
            else
            {
	        	_userList = new ArrayCollection();
	        	favorites = new ArrayCollection();
	        	messages = new ArrayCollection();
				userHash = new HashTable(500);
				tweetBeat = new Timer(30000);
				twitter = new TwitterConnector();
				switchIndex = 0;
            }
        }
        
        private function resetTwitterEngine():void
        {
        	_userList.removeAll();
        	favorites.removeAll();
        	messages.removeAll();
			userHash = new HashTable(500);
			tweetBeat = new Timer(30000);
			twitter = new TwitterConnector();
			switchIndex = 0;
        }

        public static function get instanceOfTwitterEngine():FactoryManager
        {
            return _instanceOfTwitterEngine;
        }
        		
		public function setCredentials(user:TwitterUser, password:String):void
		{
			resetTwitterEngine();
			
			this._user = user;
			
			dispatchUser();
			
			twitter.setAuthenticationCredentials(user.screenName, password);
			
			twitter.addEventListener(TwitterEvent.ON_ERROR,twitterErrorEventHandler);
			twitter.addEventListener(TwitterEvent.ON_FRIENDS_RESULT, initFriends);
 			
 			twitter.loadFriends(user.screenName,false);
		}
		
		private function twitterErrorEventHandler(e:TwitterEvent):void
		{
			Alert.show(e.toString());
		}
		
		/**
		 * initilization section
		 **/
		private function initFriends(e:TwitterEvent):void
		{
			//userList.addItem(user);
			var holder:ArrayCollection = new ArrayCollection();
			for(var i:int = 0; i < e.data.length; i++){
				var user:TwitterUser = TwitterUser(e.data[i]);
				user.hasBeenInit = false;
				user.startBitmapLoad();
				holder.addItem(user);
				userHash.insert(user.id,user);
				user.statuses.addItem(user.status);
			}
			_userList.removeAll();
			_userList.addAll(holder);
			
			dispatchFriends();
			
			twitter.removeEventListener(TwitterEvent.ON_FRIENDS_RESULT, initFriends);
			twitter.addEventListener(TwitterEvent.ON_FRIENDS_TIMELINE_RESULT, initStatuses);
			twitter.loadFriendsTimeline(user.screenName,200);
		}
		
		private function initStatuses(e:TwitterEvent):void
		{
			lastStatusId = e.data[0].id;
			recursiveTweetParser(e.data, 0);
			for each(var currUser:TwitterUser in _userList){
				currUser.hasBeenInit = true;
			}
			
			twitter.removeEventListener(TwitterEvent.ON_FRIENDS_TIMELINE_RESULT, initStatuses);
			twitter.addEventListener(TwitterEvent.ON_GET_DIRECT_MESSAGES,initMessages); //twitter.addEventListener(TwitterEvent.ON_FAVORITES,initFavorites);
			this.twitter.loadDirectMessages(); // twitter.loadFavorites(user.id.toString());
		}
		private function recursiveTweetParser(tweets:Object, index:int):void
		{
			if(index < tweets.length)
			{
				var user:TwitterUser = TwitterUser(userHash.find(tweets[index].user.id));
				if(user != null && !user.hasBeenInit)
				{
					user.statuses.removeAll();
					user.hasBeenInit = true;
				}
				recursiveTweetParser(tweets, index + 1);
				if(user != null)
				{
					user.statuses.addItemAt(tweets[index],0);
					if(user.statuses.length >= 20)
					{
						for(var index:int = 20; index < user.statuses.length; index++)
						{
							user.statuses.removeItemAt(index);
						}
					}
				}
			}
		}
		
		private function initFavorites(e:TwitterEvent):void
		{
			for each(var currStatus:TwitterStatus in e.data)
			{
				favorites.addItem(currStatus);
			}
			
			twitter.removeEventListener(TwitterEvent.ON_FAVORITES,initFavorites);
			twitter.addEventListener(TwitterEvent.ON_GET_DIRECT_MESSAGES,initMessages);
			this.twitter.loadDirectMessages();
			
			dispatchFavorites();
		}
		
		private function initMessages(e:TwitterEvent):void
		{
			lastMessageId = 0;
			for(var i:int = e.data.length-1; i >= 0; i--)
			{
				messages.addItem(e.data[i]);
				if(e.data[i].createdAt.time > lastMessageId)
				{
					lastMessageId = e.data[i].createdAt.time;
				}
			}
			
			twitter.removeEventListener(TwitterEvent.ON_GET_DIRECT_MESSAGES,initMessages);
			
			dispatchMessages();
			startTwitterUpdates();
		}
		
		
		
		
		/**
		 * starting the updates
		 */
		private function startTwitterUpdates():void
		{
			
			
			twitter.addEventListener(TwitterEvent.ON_FRIENDS_TIMELINE_RESULT, updateStatuses);
			twitter.addEventListener(TwitterEvent.ON_GET_DIRECT_MESSAGES, updateMessages);
			twitter.addEventListener(TwitterEvent.ON_FRIENDS_RESULT, gcUsers);
			tweetBeat.addEventListener(TimerEvent.TIMER,tweetTimerFunction);
			function tweetTimerFunction(e:TimerEvent):void
			{
				switch (switchIndex.toString())
				{
					case "0":
						twitter.loadDirectMessages();
						break;
					case "1":
						twitter.loadFriendsTimeline(user.screenName);
						break;
					case "2":
						twitter.loadFriends(user.screenName);
						break;
					case "3":
						twitter.loadFriendsTimeline(user.screenName);
						break;
				}
				switchIndex = (switchIndex + 1) % 4;
			}
			tweetBeat.start();
		}
		


		/**
		 * the functions used to update engine
		 */
		private function updateStatuses(e:TwitterEvent):void
		{
			var tweetsRecived:Boolean = false;
			for(var i:int = e.data.length-1; i >= 0; i--)
			{
				if(userHash.find(e.data[i].user.id) == null && e.data[i].user.id != user.id)
				{
					e.data[i].user.startBitmapLoad();
					_userList.addItem(e.data[i].user);
					userHash.insert(e.data[i].user.id, e.data[i].user);
					dispatchFriends();
				}
				
				if(e.data[i].id > lastStatusId && e.data[i].user.id != user.id)
				{
					tweetsRecived = true;
					var currUser:TwitterUser = TwitterUser(userHash.find(e.data[i].user.id));
					currUser.statuses.addItemAt(e.data[i], 0);
					lastStatusId = e.data[i].id;
					if(currUser.statuses.length >= 20)
					{
						for(var index:int = 20; index < currUser.statuses.length; index++)
						{
							currUser.statuses.removeItemAt(index);
						}
					}
					dispatchStatuses();
				}
			}
			//if(tweetsRecived)dispatchStatuses();
		}
		
		private function updateMessages(e:TwitterEvent):void
		{
			var newMessages:Boolean = false;
			for(var i:int = e.data.length-1; i >= 0; i--)
			{
				if(e.data[i].createdAt.time > lastMessageId)
				{
					messages.addItem(e.data[i]);
					lastMessageId = e.data[i].createdAt.time;
					newMessages = true;
				}
			}
			if(newMessages)
			{
				dispatchMessages();
			}
		}
		
		private function gcUsers(e:TwitterEvent):void
		{
			
			var holder:HashTable = new HashTable(e.data.length * 5);
			for(var i:int = 0; i < e.data.length; i++)
			{
				holder.insert(e.data[i].id, e.data[i]);
			}
			
			//checking for removed users
			for each(var currUser:TwitterUser in _userList)
			{
				var holderUser:TwitterUser = holder.find(currUser.id);
				if(holder.find(currUser.id) == null)
				{
					userHash.find(currUser.id).isDead = true;
					userHash.find(currUser.id).statuses.removeAll();
					_userList.removeItemAt(_userList.getItemIndex(userHash.find(currUser.id)));
					userHash.remove(currUser.id);
					dispatchFriends();
				}
			}
			
			//checking for added users
			for each(var newUser:TwitterUser in e.data)
			{
				if(userHash.find(newUser.id) == null && newUser.id != user.id)
				{
					newUser.startBitmapLoad();
					_userList.addItem(newUser);
					userHash.insert(newUser.id, newUser);
					dispatchFriends();
				}
			}
		}
		
		
		
		/**
		 * event dispatches
		 */
		private function dispatchFriends():void
		{
			var eventHolder:TwitterEngineEvent = new  TwitterEngineEvent(TwitterEngineEvent.FRIENDS_UPDATED);
			eventHolder.data = _userList;
			dispatchEvent(eventHolder);
		}
		
		private function dispatchUser():void
		{
			var eventHolder:TwitterEngineEvent = new  TwitterEngineEvent(TwitterEngineEvent.NEW_USER);
			eventHolder.data = _user;
			dispatchEvent(eventHolder);
		}
		
		private function dispatchStatuses():void
		{
			var eventHolder:TwitterEngineEvent = new  TwitterEngineEvent(TwitterEngineEvent.STATUS_UPDATED);
			dispatchEvent(eventHolder);
		}
		
		private function dispatchFavorites():void
		{
			var eventHolder:TwitterEngineEvent = new  TwitterEngineEvent(TwitterEngineEvent.FAVORITES_UPDATED);
			dispatchEvent(eventHolder);
		}
		
		private function dispatchMessages():void
		{
			var eventHolder:TwitterEngineEvent = new  TwitterEngineEvent(TwitterEngineEvent.MESSAGE_UPDATED);
			dispatchEvent(eventHolder);
		}
		
		
		
		
		/**
		 * functions for interating with twitter information
		 */
		public function sendTweet(tweet:String):void
		{
			if(user != null)
			{
				this.twitter.setStatus(tweet);
			}
		}

		public function addFavorite(status:TwitterStatus):void
		{
			if(user != null)
			{
				this.twitter.addEventListener(TwitterEvent.ON_FAVORITE_CREATED, wasCreated);
				function wasCreated(e:TwitterEvent = null):void
				{
					favorites.addItem(status);
					twitter.removeEventListener(TwitterEvent.ON_FAVORITE_CREATED, wasCreated);
					dispatchFavorites();
				}
				wasCreated();
				
				//this.twitter.createFavorite(status.id.toString());
			}
		}

		public function removeFavorite(status:TwitterStatus):void
		{
			if(user != null)
			{
				this.twitter.addEventListener(TwitterEvent.ON_FAVORITES_DESTROYED, wasDestroyed);
				function wasDestroyed(e:TwitterEvent = null):void
				{
					favorites.removeItemAt(favorites.getItemIndex(status));
					twitter.removeEventListener(TwitterEvent.ON_FAVORITES_DESTROYED, wasDestroyed);
					
					var u:TwitterUser = userHash.find(status.user.id)
					if(u != null)
					{
						for each(var s:TwitterStatus in u.statuses)
						{
							if(s.id == status.id)
							{
								s.favorited = false;
								break;
							}
						}
					}
					
					dispatchFavorites();
				}
				wasDestroyed();
				
				//this.twitter.destroyFavorite(status.id.toString());
			}
		}
		
		public function sendMessage(recipient:String, message:String):void
		{
			if(user != null)
			{
				this.twitter.sendDirectMessage(recipient, message);
			}
		}
		
		public function searchFor(search:TwitterSearch):void
		{
			this.twitter.addEventListener(TwitterEvent.ON_SEARCH, searchResults);
			function searchResults(e:TwitterEvent):void
			{
				throw e.data;
			}
			this.twitter.search(search);
		}
	}
}











