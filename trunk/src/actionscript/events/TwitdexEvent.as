package actionscript.events
{
	import flash.events.Event;

	public class TwitdexEvent extends Event
	{
        // Define static constant.
        //public static const NEW_FRIENDS:String = "newFriends";
        
        private var _data:Object;

		public function TwitdexEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public function get data():Object
		{
			return this._data;
		}
		
		public function set data(data:Object):void
		{
			this._data = data;
		}
		
        // Override the inherited clone() method.
        override public function clone():Event {
            return new TwitdexEvent(type);
        }
	}
}