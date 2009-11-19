package actionscript.behaviors
{
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemTrayIcon;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.NativeWindowDisplayState;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NativeWindowDisplayStateEvent;
	import flash.net.URLRequest;
	
	import mx.core.WindowedApplication;
	
	public class DockingBehavior
	{
		protected var dockImage:BitmapData;
		protected var window:WindowedApplication;
		private var nativeApplication:NativeApplication;
		
		public function DockingBehavior(window:Twitdex, 
										nativeApplication:NativeApplication)
		{
			this.window = window;
			this.nativeApplication = nativeApplication;
			
			//Use the loader object to load an image, which will be used for the systray       //After the image has been loaded into the object, we can prepare the application       //for docking to the system tray 
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, prepareForSystray);
			loader.load(new URLRequest("assets/logo.png"));
			 
			//Catch the closing event so that the user can decide if it wants to dock or really       //close the application 
			window.minBtn.addEventListener(MouseEvent.CLICK, closingApplication);
		}
			
		protected function closingApplication(evt:Event):void
		{
			//Don't close, so prevent the event from happening 
			
			evt.preventDefault();
			 
			dock();
		}
		
		protected function prepareForSystray(event:Event):void
		{
			//Retrieve the image being used as the systray icon 
			dockImage = event.target.content.bitmapData;
			 
			//For windows systems we can set the systray props       //(there's also an implementation for mac's, it's similar and you can find it on the net... ;) ) 
			if (NativeApplication.supportsSystemTrayIcon){
				setSystemTrayProperties();
				   
				//Set some systray menu options, so that the user can right-click and access functionality          //without needing to open the application          
				SystemTrayIcon(NativeApplication.nativeApplication.icon).menu = createSystrayRootMenu();
			}
		}
		
		protected function createSystrayRootMenu():NativeMenu
		{
		//Add the menuitems with the corresponding actions 
			var menu:NativeMenu = new NativeMenu();
			var openNativeMenuItem:NativeMenuItem = new NativeMenuItem("Open");
			var exitNativeMenuItem:NativeMenuItem = new NativeMenuItem("Exit");
			//What should happen when the user clicks on something...       
			
			openNativeMenuItem.addEventListener(Event.SELECT, undock);
			
			exitNativeMenuItem.addEventListener(Event.SELECT, closeApp);
			//Add the menuitems to the menu 
			menu.addItem(openNativeMenuItem);
			menu.addItem(new NativeMenuItem("",true));
			//separator 
			menu.addItem(exitNativeMenuItem);
			 
			return menu;
		}
		
		protected function setSystemTrayProperties():void{
			//Text to show when hovering of the docked application icon       
			SystemTrayIcon(NativeApplication.nativeApplication.icon).tooltip = "Systray test application";
			   
			//We want to be able to open the application after it has been docked       
			SystemTrayIcon(NativeApplication.nativeApplication.icon).addEventListener(MouseEvent.CLICK, undock);
			   
			//Listen to the display state changing of the window, so that we can catch the minimize       
			window.stage.nativeWindow.addEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGING, nwMinimized); //Catch the minimize event 
		}
		
		protected function nwMinimized(displayStateEvent:NativeWindowDisplayStateEvent):void
		{
		
			//Do we have an minimize action?
			//The afterDisplayState hasn't happened yet, but only describes the state the window will go to,       //so we can prevent it! 
			if(displayStateEvent.afterDisplayState == NativeWindowDisplayState.MINIMIZED)
			{
				//Prevent the windowedapplication minimize action from happening and implement our own minimize          //The reason the windowedapplication minimize action is caught, is that if active we're not able to          //undock the application back neatly. The application doesn't become visible directly, but only after clicking          //on the taskbars application link. (Not sure yet what happens exactly with standard minimize) 
				displayStateEvent.preventDefault();
				   
				//Dock (our own minimize) 
				dock();
			}
		}
		
		protected function dock():void
		{
			//Hide the applcation 
			window.stage.nativeWindow.visible = false;
			 
			//Setting the bitmaps array will show the application icon in the systray 
			NativeApplication.nativeApplication.icon.bitmaps = [dockImage];
		}
		
		protected function undock(evt:Event):void {
			//After setting the window to visible, make sure that the application is ordered to the front,       //else we'll still need to click on the application on the taskbar to make it visible 
			window.stage.nativeWindow.visible = true;
			window.stage.nativeWindow.orderToFront();
			 
			//Clearing the bitmaps array also clears the applcation icon from the systray 
			NativeApplication.nativeApplication .icon.bitmaps = [];
		}
		
		
		protected function closeApp(evt:Event):void {
			window.stage.nativeWindow.close();
		}
	}
}
	