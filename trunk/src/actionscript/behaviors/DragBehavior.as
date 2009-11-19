package actionscript.behaviors
{

	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.desktop.NativeDragOptions;
	import flash.display.BitmapData;
	import flash.display.InteractiveObject;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import mx.core.UIComponent;
	import mx.formatters.DateFormatter;
	import mx.graphics.codec.PNGEncoder;
	
	/**
	 * This class adds behavior to drag a bitmap/PNG to the desktop or other applications 
	 * from within AIR. 
	 */ 
	public class DragBehavior
	{
		private var dragSource:InteractiveObject;
		private var imageSource:InteractiveObject;
		private var maxProxyWidth : uint;
		private var maxProxyHeight : uint;
		private var fileNamePrefix : String;
		
		private var dateFormatter:DateFormatter;
		private var bitmapData : BitmapData;
		
		/**
		 * Constructor
		 * @param dragSource The object that we listen to for drag movements
		 * @param imageSource The object that we use to generate the image export.
		 * @param fileNamePrefix The prefix for filename export if needed.
		 * @param maxProxyWidth The maximum width of the drag proxy preview image.
		 * @param maxProxyHeight The maximum height of the drag proxy preview image.
		 */ 
		public function DragBehavior( dragSource:InteractiveObject,
											imageSource:InteractiveObject,
											fileNamePrefix:String = "export-",
											maxProxyWidth:uint = 300, 
											maxProxyHeight:uint = 300 )
		{
			this.dragSource = dragSource;
			this.imageSource = imageSource;
			this.maxProxyWidth = maxProxyWidth;
			this.maxProxyHeight = maxProxyHeight;
			this.fileNamePrefix = fileNamePrefix;
			
			dateFormatter = new DateFormatter();
			dateFormatter.formatString = "YYYY-MM-DD";
			
			dragSource.addEventListener( MouseEvent.MOUSE_DOWN, startDragging );
		}
		
		private function startDragging(event:MouseEvent):void
		{
			if ( !event.buttonDown ) 
			{
				return;
			}

			var options:NativeDragOptions = new NativeDragOptions();
			
			options.allowCopy = true;
			options.allowLink = false;
			options.allowMove = false;
			
			bitmapData = getBitmapData();

			var clipboard:Clipboard = new Clipboard();
			clipboard.setData( ClipboardFormats.BITMAP_FORMAT, bitmapData );


			NativeDragManager.doDrag( imageSource, clipboard, getProxyData(), null, options );
		}
		
		/** 
		 * Get an image proxy that has an arbitrary 
		 */
		private function getProxyData() : BitmapData
		{
			var proxyRect : Rectangle = scaleAndInscribe( imageSource.getBounds( imageSource ), new Rectangle( 0, 0, 300, 300 ), false );
			
			//trace("proxyRect: " + proxyRect);
			
			var scaleRatio : Number = proxyRect.width / imageSource.width;
			
			var transformMatrix : Matrix = new Matrix();
			transformMatrix.scale( scaleRatio, scaleRatio );
			
			var colorTransform : ColorTransform = new ColorTransform();
			colorTransform.alphaMultiplier = 0.70;
			
			var proxyData : BitmapData = new BitmapData( proxyRect.width, proxyRect.height, true, 0x99FFFFFF );
			proxyData.draw( imageSource, transformMatrix, colorTransform  ); 
			
			return proxyData;
		}
			
		private function getBitmapData():BitmapData
		{
			var bd:BitmapData = new BitmapData( imageSource.width, imageSource.height, false);
			bd.draw( imageSource );
			return bd;
		}

		private function createTempPNG():File
		{
			var file:File = File.createTempDirectory().resolvePath( fileNamePrefix + dateFormatter.format(new Date())+".png");
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeBytes(encodePNG());
			fileStream.close();
			return file;
		}

		private function encodePNG():ByteArray
		{
			var pngEncoder:PNGEncoder = new PNGEncoder();
			var bytes:ByteArray = pngEncoder.encode(bitmapData);
			return bytes;
		}
		
		
	
		/**
		 * Scale one rectangle to be inscribed into the other Rectangle, maintaining aspect ratio.
		 * 
		 * @param rect The rectangle that will get scaled or inscribed.
		 * @param viewportRect The rectangle that will enclose the rect
		 * @param scaleUp true if it should scale up (if necessary) to provide proper inscription; false if we should just center.
		 * @return The rectangle that represents the inscribed rectangle positioning relative to the viewportRect x,y position.
		 * 
		 * NOTE: This is a utility function that should likely be in a separate class. Included here for simplicity.
		 */
		private function scaleAndInscribe( rect:Rectangle, viewportRect:Rectangle, scaleUp:Boolean = true ) : Rectangle
		{
			var res:Rectangle = new Rectangle();
			
			
			if ( ! scaleUp && rect.width <= viewportRect.width && rect.height <= viewportRect.height )
			{
				res.width = rect.width;
				res.height = rect.height;
				
			}
			else
			{
				// determine constraining dimension	
				var scale:Number = Math.min( viewportRect.width / rect.width, viewportRect.height / rect.height );
	
				res.width = rect.width * scale;
				res.height = rect.height * scale;	
			}
			
			res.x = viewportRect.x + ( viewportRect.width - res.width ) / 2;
			res.y = viewportRect.y + ( viewportRect.height - res.height ) / 2;
	
			return res;
		}
	}
		
}
	