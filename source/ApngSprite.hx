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
	public var paused(default, set):Bool = false;
	public var reversed(default, set):Bool = false;
	public var apngFrame(get, set):Int;
	public var onLoop(default, null):FlxSignal = new FlxSignal();
	public var onComplete(default, null):FlxSignal = new FlxSignal();

	var baseFrameRate:Float = 30;
	var lastFrameIndex:Int = 0;
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

		var data = ApngCache.get(path);
		if (data == null)
		{
			makeGraphic(32, 32, FlxColor.MAGENTA);
			return this;
		}

		numPlays = data.numPlays;
		loadGraphic(FlxG.bitmap.add(data.sheet, false, "apng:" + path), true, data.frameWidth, data.frameHeight);

		var total = 0;
		for (delay in data.delaysMs)
			total += delay;
		baseFrameRate = frameRate != null ? frameRate : 1000 * data.delaysMs.length / Math.max(total, 1);

		animation.add("apng", [for (i in 0...data.delaysMs.length) i], baseFrameRate * speed, true);
		animation.play("apng", false, reversed);
		animation.curAnim.paused = paused;
		lastFrameIndex = animation.frameIndex;
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

		if (animation.curAnim != null)
		{
			var cur = animation.frameIndex;
			if ((!reversed && cur < lastFrameIndex) || (reversed && cur > lastFrameIndex))
			{
				onLoop.dispatch();
				playsDone++;
				if (numPlays > 0 && playsDone >= numPlays)
				{
					paused = true;
					onComplete.dispatch();
				}
			}
			lastFrameIndex = cur;
		}
	}

	override public function destroy():Void
	{
		ApngCache.onCleared.remove(onCacheCleared);
		super.destroy();
		onLoop.removeAll();
		onComplete.removeAll();
	}

	function onCacheCleared():Void
	{
		if (apngPath != null)
			needsReload = true;
	}

	function set_speed(value:Float):Float
	{
		value = FlxMath.bound(value, 0.05, 10);
		speed = value;
		if (animation.curAnim != null)
			animation.curAnim.frameRate = baseFrameRate * value;
		return value;
	}

	function set_paused(value:Bool):Bool
	{
		paused = value;
		if (animation.curAnim != null)
			animation.curAnim.paused = value;
		return value;
	}

	function set_reversed(value:Bool):Bool
	{
		reversed = value;
		if (animation.curAnim != null)
		{
			animation.play("apng", true, value, animation.frameIndex);
			animation.curAnim.paused = paused;
		}
		return value;
	}

	function get_apngFrame():Int
	{
		return animation.curAnim != null ? animation.frameIndex : 0;
	}

	function set_apngFrame(value:Int):Int
	{
		if (animation.curAnim != null)
			animation.frameIndex = value;
		return value;
	}
}
