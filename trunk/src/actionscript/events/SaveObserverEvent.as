package actionscript.events
{
	import flash.events.Event;
	
	public class SaveObserverEvent extends TwitdexEvent
	{
        // Define static constant.
        public static const SAVES_UPDATED:String = "savesUpdated";
        
		public function SaveObserverEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
        // Override the inherited clone() method.
        override public function clone():Event {
            return new SaveObserverEvent(type);
        }
	}
}