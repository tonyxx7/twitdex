package actionscript.events
{
	import flash.events.Event;

	public class TwitterEngineEvent extends TwitdexEvent
	{
       public static const NEW_USER:String = "newUser";
        
        public static const FRIENDS_UPDATED:String = "friendsUpdated";
        
        public static const STATUS_UPDATED:String = "statusUpdated";
        
        public static const FAVORITES_UPDATED:String = "favoritesUpdated";
        
        public static const MESSAGE_UPDATED:String = "messageUpdated";
        
		public function TwitterEngineEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
        // Override the inherited clone() method.
        override public function clone():Event {
            return new TwitterEngineEvent(type);
        }
	}
}