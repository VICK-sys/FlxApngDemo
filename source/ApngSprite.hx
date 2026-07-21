package;

import ApngDecoder.ApngData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;

class ApngSprite extends FlxSprite
{
	public var speed(default, set):Float = 1;
	public var paused:Bool = false;
	public var reversed:Bool = false;
	public var apngFrame(get, set):Int;
	public var onLoop(default, null):FlxSignal = new FlxSignal();
	public var onComplete(default, null):FlxSignal = new FlxSignal();

	var delays:Array<Float>;
	var frameTimer:Float = 0;
	var apngPath:String;
	var customFrameRate:Null<Float>;
	var needsReload:Bool = false;
	var numPlays:Int = 0;
	var playsDone:Int = 0;

	public function new(?x:Float = 0, ?y:Float = 0, ?path:String)
	{
		super(x, y);
		ApngCache.onCleared.add(onCacheCleared);
		if (path != null)
			loadApng(path);
	}

	public function loadApng(path:String, ?frameRate:Float):ApngSprite
	{
		apngPath = path;
		customFrameRate = frameRate;
		playsDone = 0;
		frameTimer = 0;
		delays = null;

		var data = ApngCache.get(path);
		if (data == null)
		{
			makeGraphic(32, 32, FlxColor.MAGENTA);
			return this;
		}

		numPlays = data.numPlays;
		loadGraphic(FlxG.bitmap.add(data.sheet, false, "apng:" + path), true, data.frameWidth, data.frameHeight);

		if (frameRate != null && frameRate > 0)
			delays = [for (_ in data.delaysMs) 1 / frameRate];
		else
			delays = [for (d in data.delaysMs) d / 1000];

		animation.frameIndex = 0;
		return this;
	}

	override public function update(elapsed:Float):Void
	{
		if (needsReload)
		{
			needsReload = false;
			loadApng(apngPath, customFrameRate);
		}

		super.update(elapsed);

		if (delays != null && delays.length > 1 && !paused)
		{
			frameTimer += elapsed * speed;
			var idx = animation.frameIndex;
			var guard = 0;
			while (frameTimer >= delays[idx] && guard++ < 1000)
			{
				frameTimer -= delays[idx];
				if (!reversed)
				{
					idx++;
					if (idx >= delays.length)
					{
						idx = 0;
						if (finishLoop())
						{
							idx = delays.length - 1;
							break;
						}
					}
				}
				else
				{
					idx--;
					if (idx < 0)
					{
						idx = delays.length - 1;
						if (finishLoop())
						{
							idx = 0;
							break;
						}
					}
				}
			}
			animation.frameIndex = idx;
		}
	}

	override public function destroy():Void
	{
		ApngCache.onCleared.remove(onCacheCleared);
		super.destroy();
		onLoop.removeAll();
		onComplete.removeAll();
	}

	function finishLoop():Bool
	{
		onLoop.dispatch();
		playsDone++;
		if (numPlays > 0 && playsDone >= numPlays)
		{
			paused = true;
			onComplete.dispatch();
			return true;
		}
		return false;
	}

	function onCacheCleared():Void
	{
		if (apngPath != null)
			needsReload = true;
	}

	function set_speed(value:Float):Float
	{
		return speed = FlxMath.bound(value, 0.05, 10);
	}

	function get_apngFrame():Int
	{
		return animation.frameIndex;
	}

	function set_apngFrame(value:Int):Int
	{
		if (delays != null)
		{
			frameTimer = 0;
			animation.frameIndex = Std.int(FlxMath.bound(value, 0, delays.length - 1));
		}
		return value;
	}
}
