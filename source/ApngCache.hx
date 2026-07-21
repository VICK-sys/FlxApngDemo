package;

import ApngDecoder.ApngData;
import flixel.FlxG;
import flixel.util.FlxSignal;
import openfl.utils.Assets;

class ApngCache
{
	public static var onCleared(default, null):FlxSignal = new FlxSignal();

	static var apngs:Map<String, ApngData> = [];
	static var autoClearEnabled:Bool = false;

	public static function get(path:String):Null<ApngData>
	{
		if (apngs.exists(path))
			return apngs.get(path);

		var data:ApngData = null;
		var t0 = haxe.Timer.stamp();
		try
		{
			data = ApngDecoder.decode(Assets.getBytes(path));
		}
		catch (e:Dynamic)
		{
			FlxG.log.warn('ApngCache: failed to decode "$path": $e');
			trace('ApngCache: failed to decode "$path": $e');
		}

		if (data != null)
		{
			trace('ApngCache: decoded "$path" (${data.delaysMs.length} frames) in ${Math.round((haxe.Timer.stamp() - t0) * 1000)}ms');
			if (data.sheet.width > 4096 || data.sheet.height > 4096)
				FlxG.log.warn('ApngCache: spritesheet for "$path" exceeds 4096px, may fail on older or mobile GPUs');

			var graphic = FlxG.bitmap.add(data.sheet, false, "apng:" + path);
			graphic.persist = true;
			graphic.destroyOnNoUse = false;

			apngs.set(path, data);
		}
		return data;
	}

	public static function enableAutoClear():Void
	{
		if (autoClearEnabled)
			return;
		autoClearEnabled = true;
		FlxG.signals.preStateSwitch.add(clear);
	}

	public static function clear():Void
	{
		for (path in apngs.keys())
			FlxG.bitmap.removeByKey("apng:" + path);
		apngs.clear();

		onCleared.dispatch();
	}
}
