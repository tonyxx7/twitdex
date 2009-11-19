package actionscript.behaviors
{
	import actionscript.events.SaveObserverEvent;
	import actionscript.events.TwitterEngineEvent;
	import actionscript.factories.FactoryManager;
	import actionscript.observers.SaveObserver;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemTrayIcon;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	
	import uis.tabcomponents.OpenWindow;

	public class TwitdexDockingBehavior extends DockingBehavior
	{
		private var saveObserver:SaveObserver = SaveObserver.instanceOfSaveObserver;
		
		private var twitterEngine:FactoryManager = FactoryManager.instanceOfTwitterEngine;
		
		private var openWindow:OpenWindow;
		
		public function TwitdexDockingBehavior(window:Twitdex, 
											   nativeApplication:NativeApplication, 
											   openWindow:OpenWindow)
		{
			super(window, nativeApplication);
			
			this.openWindow = openWindow;
			
			twitterEngine.addEventListener(TwitterEngineEvent.NEW_USER, resetMenu);
			saveObserver.addEventListener(SaveObserverEvent.SAVES_UPDATED, resetMenu);
			function resetMenu(e:Event = null):void
			{
				SystemTrayIcon(NativeApplication.nativeApplication.icon).menu = createSystrayRootMenu();
			}
		}
		
		override protected function createSystrayRootMenu():NativeMenu
		{
			//Add the menuitems with the corresponding actions 
			var menu:NativeMenu = new NativeMenu();
			
			if(saveObserver.getUserXML() != null)
			{
				for each(var xmlHolder:XML in saveObserver.getUserXML().windows.children())
				{
					var windowNativeMenuItem:NativeMenuItem = new NativeMenuItem(xmlHolder.@title);
					windowNativeMenuItem.addEventListener(Event.SELECT, openAWindow);
					menu.addItem(windowNativeMenuItem);
					
				}
			}
			
			menu.addItem(new NativeMenuItem("",true)); // separator 
			
			var openNativeMenuItem:NativeMenuItem = new NativeMenuItem("Open");
			openNativeMenuItem.addEventListener(Event.SELECT, undock);
			menu.addItem(openNativeMenuItem);
			
			menu.addItem(new NativeMenuItem("",true)); // separator 
			
			var exitNativeMenuItem:NativeMenuItem = new NativeMenuItem("Exit");
			exitNativeMenuItem.addEventListener(Event.SELECT, closeApp);
			menu.addItem(exitNativeMenuItem);
			
			return menu;
		}
		
		private function openAWindow(e:Event):void
		{
			openWindow.openWindow(e.target.label);
		}
		
		override protected function closeApp(evt:Event):void
		{
			openWindow.closeWindows();
			window.stage.nativeWindow.close();
		}
	}
}




