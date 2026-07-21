package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	var ball:ApngSprite;
	var julian:ApngSprite;
	var status:FlxText;
	var loops:Int = 0;

	override public function create()
	{
		super.create();
		ApngCache.enableAutoClear();

		add(makeChecker());

		julian = new ApngSprite(0, 0, AssetPaths.julian__png);
		julian.antialiasing = true;
		julian.screenCenter();
		julian.x = 60;
		add(julian);

		ball = new ApngSprite(0, 0, AssetPaths.ball__png);
		ball.antialiasing = true;
		ball.screenCenter();
		ball.x = 420;
		add(ball);

		ball.onLoop.add(() -> loops++);

		var indexed = new ApngSprite(180, 350, AssetPaths.indexed__png);
		add(indexed);

		var stat = new ApngSprite(350, 350, AssetPaths.static__png);
		add(stat);

		status = new FlxText(0, 8, FlxG.width, "", 12);
		status.alignment = CENTER;
		status.color = FlxColor.BLACK;
		add(status);

		var help = new FlxText(0, 448, FlxG.width, "SPACE pause | LEFT/RIGHT speed | R reverse", 12);
		help.alignment = CENTER;
		help.color = FlxColor.BLACK;
		add(help);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
		{
			var pause = !ball.paused;
			ball.paused = pause;
			julian.paused = pause;
		}

		if (FlxG.keys.justPressed.RIGHT)
			setSpeed(ball.speed + 0.25);
		if (FlxG.keys.justPressed.LEFT)
			setSpeed(ball.speed - 0.25);
		if (FlxG.keys.justPressed.R)
		{
			ball.reversed = !ball.reversed;
			julian.reversed = !julian.reversed;
		}

		status.text = 'APNG | speed x${ball.speed}'
			+ (ball.paused ? " | paused" : "")
			+ (ball.reversed ? " | reversed" : "")
			+ ' | loops: $loops';
	}

	function setSpeed(value:Float)
	{
		value = Math.max(0.25, Math.min(4, value));
		ball.speed = value;
		julian.speed = value;
	}

	function makeChecker():FlxSprite
	{
		var checker = new FlxSprite(0, 0);
		checker.makeGraphic(FlxG.width, FlxG.height, 0xFFE8E8E8, true);
		var size = 16;
		for (row in 0...Std.int(FlxG.height / size))
			for (col in 0...Std.int(FlxG.width / size))
				if ((row + col) % 2 == 0)
					checker.pixels.fillRect(new openfl.geom.Rectangle(col * size, row * size, size, size), 0xFFCCCCCC);
		checker.dirty = true;
		return checker;
	}
}
