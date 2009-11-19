package actionscript.observers
{
	import actionscript.data.TwitterUser;
	import actionscript.events.SaveObserverEvent;
	import actionscript.factories.FactoryManager;
	
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	public final class SaveObserver extends EventDispatcher
	{
		private var twitterEngine:FactoryManager = FactoryManager.instanceOfTwitterEngine;
		private static var _instanceOfSaveObserver:SaveObserver = new SaveObserver();
		private var f:File = File.applicationStorageDirectory.resolvePath("Twitdex/Saves.xml");
		
		[Bindable]
		private var _saveXML:XMLList;
		public function get saveXML():XMLList{return _saveXML;}
		
        public function SaveObserver()
        {
            if (_instanceOfSaveObserver != null){
                throw new Error("SaveObserver is a Singleton and can only be accessed through SaveObserver.instanceOfSaveObserver");
            }else{
            	initXMLFile();
            }
        }

        public static function get instanceOfSaveObserver():SaveObserver
        {
            return _instanceOfSaveObserver;
        }
        
		private function initXMLFile():void
		{
			//Try reading in the file
			//if(f.exists)f.deleteFile();
			if(f.exists){
				//If successful, create an XML stream for the config file
				var fs:FileStream = new FileStream();
				fs.open(f, FileMode.READ);
				_saveXML = XMLList(fs.readUTFBytes(fs.bytesAvailable));
				fs.close();
			}else{
				//If not, make the default config file
				//_saveXML = new XMLList();
				_saveXML = new XMLList();//getTestXML();
				updateSaves();
			}
		}
		
		private function updateSaves():void
		{
			if(f.exists)f.deleteFile();
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.WRITE);
			fs.writeUTFBytes(_saveXML.toXMLString());
			fs.close();
			
            dispatchEvent(new SaveObserverEvent(SaveObserverEvent.SAVES_UPDATED));
		}
			
        public function getUserXML():XML
        {
        	if(twitterEngine.user != null)
        	{
	        	var currUser:XML;
	        	for each(currUser in _saveXML){
	            	if(currUser.@name == twitterEngine.user.screenName)
	            	{
	            		break;
	            	}
	         	}
	         	return currUser;
	        }
	        else
	        {
	        	return null;
	        }
        }
        
        public function getUserWindowsXML():XMLList
        {
        	return getUserXML().windows
        }
        
        public function getUserSettingsXML():XMLList
        {
        	return getUserXML().Settings
        }
        
        public function addNewUser(newUser:String):void
        {
			var exists:Boolean = false;
			for each(var currUser:XML in _saveXML)
			{
				if(currUser.@name == newUser){
					exists = true;
				}
			}
			
			if(!exists && newUser != "")
			{
				_saveXML += XML("<user name=\"" + newUser + "\">" + 
									"<windows>" + 
										"<file title=\"all\">" + 
										"</file>" + 
									"</windows>" + 
									"<settings>" + 
										"<tweetLimit>" +
											5 +
										"</tweetLimit>" +
								"</settings>" + 
								"</user>");
				updateSaves();
			}
        }
        
        public function removeUser(removeUser:String):void
        {
			var index:int = 0;
			for each(var currUser:XML in _saveXML)
			{
				if(currUser.@name == removeUser){
					var holder:XMLList = _saveXML;
					delete holder[index];
					_saveXML = null;
					_saveXML = holder;
					updateSaves();
					return;
				}
				index++;
			}
        }
        
        public function addUserWindow(windowName:String, users:Array):Boolean
        {
        	if(twitterEngine.user != null)
        	{
	            // add window according to the user varable
	            var newWin:XMLList = new XMLList("<file title=\"" + windowName + "\"></file>");
	            for each(var userHolder:TwitterUser in users){
	            	newWin.file += XMLList("<friend user=\"" + userHolder.screenName + "\" id=\"" + userHolder.id + "\" />");
	            }
	            
	        	for each(var currUser:XML in _saveXML){
	            	if(currUser.@name == twitterEngine.user.screenName)
	            	{
	            		var index:int = 0;
	        			for each(var currFile:XML in currUser.windows.children()){
	        				if(currFile.@title == windowName)
	        				{
	        					delete currUser.windows.children()[index];
	        					break;
	        				}
	        				index++;
	        			}
	        			
	            		currUser.windows.children()[0] += newWin;
						updateSaves();
			            return true;
	            	}
	         	}
	        }
			return false;
        }
        
        public function removeUserWindow(windowName:String):Boolean
        {
        	if(twitterEngine.user != null)
        	{
	            /**/
	        	for each(var currUser:XML in _saveXML){
	            	if(currUser.@name == twitterEngine.user.screenName)
	            	{
						var index:int = 0;
	        			for each(var currFile:XML in currUser.windows.children()){
	        				if(currFile.@title == windowName)
	        				{
	        					delete currUser.windows.children()[index];
	        					updateSaves();
	        					return true;
	        				}
	        				index++;
	        			}
	            	}
	         	}
	         	/**/
	        }
            
			return false;
        }
        
        public function doesUserWindowExist(windowName:String):Boolean
        {
        	if(twitterEngine.user != null)
        	{
	            /**/
	        	for each(var currUser:XML in _saveXML){
	            	if(currUser.@name == twitterEngine.user.screenName)
	            	{
						var index:int = 0;
	        			for each(var currFile:XML in currUser.windows.children()){
	        				if(currFile.@title == windowName)
	        				{
	        					return true;
	        				}
	        				index++;
	        			}
	            	}
	         	}
	         	/**/
	        }
            
			return false;
        }
        
        public function doesUserExist(userName:String):Boolean
        {
        	for each(var currUser:XML in _saveXML){
            	if(currUser.@name == userName)
            	{
					return true;
            	}
         	}
            
			return false;
        }
        
        public function updateUserSettings(newSettings:XML):void
        {
        	if(twitterEngine.user != null)
        	{
	        	var currUser:XML;
	        	for each(currUser in _saveXML){
	            	if(currUser.@name == twitterEngine.user.screenName)
	            	{
	            		currUser.settings.tweetLimit = newSettings.tweetLimit;
	            	}
	         	}
	        }
	        
            updateSaves();
        }
        
		private function getTestXML():XMLList
		{	
			var holder:XMLList;
			
			holder = new XMLList()
			
			holder += XML(	<user name="court_c_brown">
								<windows>
									<file title="all">
									</file>
									<file title="friends">
										<friend user="smileybluedex" id="84456742" />
										<friend user="Soonerwolfie" id="14528844" />
										<friend user="pickingj" id="37304340" />
									</file>
									<file title="coworkers">
										<friend user="smileybluedex" id="84456742" />
										<friend user="pickingj" id="37304340" />
									</file>
								</windows>
								<settings>
									<tweetLimit>
										5
									</tweetLimit>
								</settings>
							</user>);
			
			holder += XML(	<user name="smileybluedex">
								<windows>
									<file title="all">
									</file>
								</windows>
								<settings>
									<tweetLimit>
										10
									</tweetLimit>
								</settings>
							</user>);
							
			return holder;
		}
	}
}