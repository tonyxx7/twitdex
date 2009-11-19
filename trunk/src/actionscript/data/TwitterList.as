package actionscript.data
{
	import mx.collections.ArrayCollection;		public class TwitterList{				public var id:Number;				public var name:String;				public var full_name:String;				public var slug:String;				public var subscriber_count:String;				public var member_count:String;		
		public var uri:String;				public var mode:String;				public var user:TwitterUser;				function TwitterUser(list:Object) {			if (list!=null){				id = list.id;				name = list.name;				full_name = list.full_name;				slug = list.slug;				subscriber_count = list.subscriber_count;				member_count = list.member_count;				uri = list.uri;				mode = list.mode;				user = new TwitterUser(list.user);
			}		}
	}}