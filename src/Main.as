package 
{
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.geom.ColorTransform;
	import flash.system.LoaderContext;

	/**
	 * ...
	 * @author umhr
	 */
	public class Main extends Sprite 
	{
		private var _mulitiLoader:MultiLoader;
		private var _xyzData:Vector.<Number>;
		private var _colorData:Vector.<int>;
		private var _matrix3D:Matrix3D;
		private var _canvas:Bitmap;
		private var _bg:Bitmap;
		private const FADE:ColorTransform = new ColorTransform(1, 1, 1, 1, -0xA, -0xA, -0xA);
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			_mulitiLoader = new MultiLoader();
			_mulitiLoader.add("earthmap200.png", { type:"image", id:"map" , context:new LoaderContext(true)} );
			_mulitiLoader.add("earthbump200.png", { type:"image", id:"bump" , context:new LoaderContext(true) } );
			_mulitiLoader.addEventListener(Event.COMPLETE, atComp);
			_mulitiLoader.start();
		}
		private function atComp(event:Event):void {
			_bg = new Bitmap(new BitmapData(stage.stageWidth, stage.stageHeight, false, 0x00000000), "auto", false);
			_bg.filters = [new BlurFilter(16, 16)];
			this.addChild(_bg);
			_canvas = new Bitmap(new BitmapData(stage.stageWidth, stage.stageHeight, true, 0x00000000),"auto",true);
			this.addChild(_canvas);
			_colorData = new Vector.<int>();
			_xyzData = new Vector.<Number>();
			_matrix3D = new Matrix3D();
			var map:BitmapData = _mulitiLoader.getBitmapData("map");
			var bump:BitmapData = _mulitiLoader.getBitmapData("bump");
			var h:int = map.height;
			var w:int = map.width;
			for (var i:int = 0; i < h; i++) {
				for (var j:int = 0; j < w; j++) {
					_colorData.push(map.getPixel32(j, i));
					var rx:Number = Math.PI * (2 * (j - (w - 1) / 2) / (w - 1));
					var ry:Number = Math.PI * ((i - (h - 1) / 2) / (h - 1));
					var scale:Number = 160 + 6 * bump.getPixel(j, i) / 0xFFFFFF;
					var nx:Number = Math.cos(ry) * Math.sin(rx) * scale;
					var ny:Number = Math.sin(ry) * scale;
					var nz:Number = Math.cos(ry) * Math.cos(rx) * scale;
					_xyzData.push(nx);
					_xyzData.push(ny);
					_xyzData.push(nz);
				}
			}
			this.addEventListener(Event.ENTER_FRAME, atEnter);
		}
		private function atEnter(event:Event):void {
			var mouseVec:Vector3D = new Vector3D(-stage.mouseY + stage.stageWidth / 2, stage.mouseX - stage.stageHeight / 2);
			mouseVec.normalize();
			_matrix3D.appendRotation(0.5, mouseVec);
			_matrix3D.appendRotation(1, Vector3D.Y_AXIS);
			var xyz:Vector.<Number> = new Vector.<Number>();
			_matrix3D.transformVectors(_xyzData, xyz);
			
			_canvas.bitmapData.lock();
			_bg.bitmapData.lock();
			_canvas.bitmapData.fillRect(new Rectangle(0, 0, 465, 465), 0x00000000);
			_bg.bitmapData.colorTransform(_canvas.bitmapData.rect, FADE);
			var n:int = xyz.length / 3;
			var vp:Number = 1000;
			for (var i:int = 0; i < n; i++) {
				if (xyz[i * 3 + 2] < 0) { continue };
				var per:Number = vp / (vp + xyz[i * 3 + 2]);
				_canvas.bitmapData.setPixel32(xyz[i * 3]/per + 465 / 2, xyz[i * 3 + 1]/per + 465 / 2, _colorData[i]);
			}
			
			_bg.bitmapData.draw(_canvas, null, null, "add");
			_canvas.bitmapData.unlock();
			_bg.bitmapData.unlock();
		}
		
	}
	
}

