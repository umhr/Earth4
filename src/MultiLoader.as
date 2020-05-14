package 
{
	/**
	 * Fileローダー
	 * ...
	 * @author umhr
	 */

	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.utils.Dictionary;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	import flash.display.MovieClip;
	public class MultiLoader{
		public static var IMAGE_EXTENSIONS:Array = ["swf", "jpg", "jpeg", "gif", "png"];
		public static var TEXT_EXTENSIONS:Array = ["txt", "js", "xml", "php", "asp"];
		public static const COMPLETE:String = "complete";
		private var _listener:Function = function(event:Event):void{};
		private var _loads:Dictionary;
		private var _keyFromId:Dictionary;
		private var _loadCount:int;
		private var _itemsLoaded:int;
		public var items:Array;
		public function MultiLoader(name:String = ""){
			_loads = new Dictionary();
			_keyFromId = new Dictionary();
			_itemsLoaded = 0;
			items = [];
		}
		public function add(url:String, props:Object = null):void {	
			var loadingItem:LoadingItem = new LoadingItem();
			loadingItem.url = url;
			loadingItem.type = getType(url, props);
			if(props){
				if(props.context){
					loadingItem.context = props.context;
				}
				if (props.id) {
					_keyFromId[props.id] = url;
				}
				if (props.preventCache) {
					loadingItem.preventCache = props.preventCache;
				}
			}
			items.push(loadingItem); 
		}
		private function getType(url:String, props:Object = null):String{
			var result:String = "";
			if (props && props.type) {
				return props.type;
			}
			var i:int;
			var extension:String;
			var n:int = IMAGE_EXTENSIONS.length;
			for (i = 0; i < n; i++) {
				extension = IMAGE_EXTENSIONS[i];
				if(extension == url.substr(-extension.length).toLowerCase()){
					result = "image";
					break;
				}
			}
			if(result == ""){
				n = TEXT_EXTENSIONS.length;
				for (i = 0; i < n; i++) {
					extension = TEXT_EXTENSIONS[i];
					if(extension == url.substr(-extension.length).toLowerCase()){
						result = "text";
						break;
					}
				}
			}
			return result;
		}
		
		public function start():void{
			var n:int = items.length;
			for (var i:int = 0; i < n; i++) {
				var type:String = items[i].type;
				var url:String = items[i].url;
				url += (items[i].preventCache)?"?rand=" + Math.random():"";
				var uRLRequest:URLRequest = new URLRequest(url);
				if(type == "image"){
					_loads[items[i].url] = loadImage(uRLRequest, items[i].context);
				}else if(type == "text"){
					_loads[items[i].url] = loadText(uRLRequest);
				}else if (type == "byteImage") {
					byteImage(uRLRequest, items[i].context);
				}
			}
		}
		public function addEventListener(type:String,listener:Function):void{
			_listener = listener;
		}
		public function getBitmap(key:String):Bitmap{
			key = keyMatching(key);
			var bitmap:Bitmap;
			try{
				if (getQualifiedClassName(_loads[key].content) == "flash.display::MovieClip") {
					var mc:MovieClip = _loads[key].content;
					var bitmapData:BitmapData = new BitmapData(mc.width, mc.height);
					bitmapData.draw(mc);
					bitmap = new Bitmap(bitmapData);
				}else {
					bitmap = _loads[key].content;
				}
			}catch (e:*) {
				//bitmap = new Bitmap();
			}
			return bitmap;
		}
		public function getBitmapData(key:String):BitmapData{
			key = keyMatching(key);
			var bitmap:Bitmap = getBitmap(key);
			var bitmapData:BitmapData = new BitmapData(bitmap.width, bitmap.height);
			bitmapData.draw(bitmap);
			return bitmapData;
		}
		private function loadImage(url:URLRequest, context:LoaderContext = null):Loader {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComp);
			loader.load(url, context);
			return loader;
		}
		private function byteImage(url:URLRequest, context:LoaderContext = null):void {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadBytes);
			loader.load(url, context);
			function loadBytes(event:Event):void {
				_loads[url.url] = new Loader();
				_loads[url.url].contentLoaderInfo.addEventListener(Event.COMPLETE, onComp);
				_loads[url.url].loadBytes(event.target.bytes);
			}
		}
		public function getBinary(key:String):ByteArray{
			return _loads[keyMatching(key)].contentLoaderInfo.bytes;
		}
		
		public function getText(key:String):String {
			key = keyMatching(key);
			return key?_loads[key].data:key;
		}
		public function getXML(key:String):XML {
			return XML(getText(key));
		}
		private function keyMatching(key:String):String {
			return _loads[key]?key:_keyFromId[key];
		}
		
		private function loadText(url:URLRequest):URLLoader{
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onComp);
			loader.load(url);
			return loader;
		}
		private function onComp(event:Event):void {
			_itemsLoaded ++;
			if (_itemsLoaded == items.length) {
				_itemsLoaded = 0;
				_listener(event);
			}
		}
		public function get itemsTotal():int{
			return items.length;
		}
		public function get itemsLoaded():int{
			return _itemsLoaded;
		}
		public function get loadedRatio():Number {
			return _itemsLoaded / items.length;
		}
	}
}

import flash.net.URLRequest;
import flash.system.LoaderContext;
class LoadingItem{
	public var url:String;
	public var preventCache:Boolean;
	public var type:String;
	public var status:String;
	public var context:LoaderContext;
	public function LoadingItem(){};
}
