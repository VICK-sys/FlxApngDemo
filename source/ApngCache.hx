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
			if (data.sheet.width > 4096 || data.sheet.height > 4096)
				FlxG.log.warn('ApngCache: spritesheet for "$path" exceeds 4096px, may fail on older or mobile GPUs');
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
