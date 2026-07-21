package;

import format.png.Data;
import format.png.Tools;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;

typedef ApngData =
{
	var sheet:BitmapData;
	var frameWidth:Int;
	var frameHeight:Int;
	var delaysMs:Array<Int>;
	var numPlays:Int;
}

private typedef RawFrame =
{
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;
	var delayMs:Int;
	var disposeOp:Int;
	var blendOp:Int;
	var data:BytesBuffer;
}

class ApngDecoder
{
	public static function decode(bytes:Bytes):ApngData
	{
		if (bytes == null || bytes.length < 8 || bytes.get(0) != 0x89 || bytes.get(1) != 0x50 || bytes.get(2) != 0x4E || bytes.get(3) != 0x47)
			throw "not a PNG file";

		var pos = 8;
		var width = 0;
		var height = 0;
		var bitDepth = 8;
		var colorType = 6;
		var palette:Bytes = null;
		var trns:Bytes = null;
		var numPlays = 0;
		var frames:Array<RawFrame> = [];
		var current:RawFrame = null;
		var defaultImage = new BytesBuffer();
		var hasDefaultImage = false;
		var sawFctlBeforeIdat = false;
		var sawIdat = false;
		var sawActl = false;

		while (pos + 8 <= bytes.length)
		{
			var len = readInt(bytes, pos);
			var type = bytes.getString(pos + 4, 4);
			var dataPos = pos + 8;

			switch (type)
			{
				case "IHDR":
					width = readInt(bytes, dataPos);
					height = readInt(bytes, dataPos + 4);
					bitDepth = bytes.get(dataPos + 8);
					colorType = bytes.get(dataPos + 9);
					if (bytes.get(dataPos + 12) != 0)
						throw "interlaced PNG not supported";
				case "PLTE":
					palette = bytes.sub(dataPos, len);
				case "tRNS":
					trns = bytes.sub(dataPos, len);
				case "acTL":
					sawActl = true;
					numPlays = readInt(bytes, dataPos + 4);
				case "fcTL":
					current = {
						width: readInt(bytes, dataPos + 4),
						height: readInt(bytes, dataPos + 8),
						x: readInt(bytes, dataPos + 12),
						y: readInt(bytes, dataPos + 16),
						delayMs: toDelayMs(readShort(bytes, dataPos + 20), readShort(bytes, dataPos + 22)),
						disposeOp: bytes.get(dataPos + 24),
						blendOp: bytes.get(dataPos + 25),
						data: new BytesBuffer()
					};
					frames.push(current);
					if (!sawIdat)
						sawFctlBeforeIdat = true;
				case "IDAT":
					sawIdat = true;
					if (current != null && sawFctlBeforeIdat)
						current.data.add(bytes.sub(dataPos, len));
					else
					{
						hasDefaultImage = true;
						defaultImage.add(bytes.sub(dataPos, len));
					}
				case "fdAT":
					if (current != null)
						current.data.add(bytes.sub(dataPos + 4, len - 4));
				case "IEND":
					break;
				default:
			}
			pos = dataPos + len + 4;
		}

		if (width <= 0 || height <= 0)
			throw "missing or invalid IHDR";

		var color = switch (colorType)
		{
			case 0: ColGrey(false);
			case 2: ColTrue(false);
			case 3: ColIndexed;
			case 4: ColGrey(true);
			case 6: ColTrue(true);
			default: throw "unsupported color type " + colorType;
		};

		if (frames.length == 0 || !sawActl)
		{
			if (!hasDefaultImage)
				throw "no image data";
			frames = [{x: 0, y: 0, width: width, height: height, delayMs: 100, disposeOp: 0, blendOp: 0, data: defaultImage}];
			numPlays = 0;
		}

		var n = frames.length;
		var cols = Std.int(Math.ceil(Math.sqrt(n)));
		var rows = Std.int(Math.ceil(n / cols));
		var sheet = new BitmapData(width * cols, height * rows, true, 0);
		var canvas = new BitmapData(width, height, true, 0);
		var delays:Array<Int> = [];
		var prevSnapshot:BitmapData = null;
		var prevRect:Rectangle = null;
		var prevDispose = 0;

		for (i in 0...n)
		{
			var f = frames[i];
			var rect = new Rectangle(f.x, f.y, f.width, f.height);

			if (i > 0)
			{
				if (prevDispose == 1)
					canvas.fillRect(prevRect, 0);
				else if (prevDispose == 2 && prevSnapshot != null)
					canvas.copyPixels(prevSnapshot, prevSnapshot.rect, new Point(prevRect.x, prevRect.y));
			}

			var dispose = f.disposeOp;
			if (i == 0 && dispose == 2)
				dispose = 1;
			if (dispose == 2)
			{
				if (prevSnapshot != null)
					prevSnapshot.dispose();
				prevSnapshot = new BitmapData(f.width, f.height, true, 0);
				prevSnapshot.copyPixels(canvas, rect, new Point(0, 0));
			}

			var frameBmp = decodeFrame(f, bitDepth, color, palette, trns);
			canvas.copyPixels(frameBmp, frameBmp.rect, new Point(f.x, f.y), null, null, f.blendOp == 1);
			frameBmp.dispose();

			sheet.copyPixels(canvas, canvas.rect, new Point((i % cols) * width, Std.int(i / cols) * height));
			delays.push(f.delayMs);
			prevDispose = dispose;
			prevRect = rect;
		}

		if (prevSnapshot != null)
			prevSnapshot.dispose();
		canvas.dispose();

		return {sheet: sheet, frameWidth: width, frameHeight: height, delaysMs: delays, numPlays: numPlays};
	}

	static function decodeFrame(f:RawFrame, bitDepth:Int, color:Color, palette:Bytes, trns:Bytes):BitmapData
	{
		var png = new List<Chunk>();
		png.add(CHeader({width: f.width, height: f.height, colbits: bitDepth, color: color, interlaced: false}));
		if (palette != null)
			png.add(CPalette(palette));
		if (trns != null)
			png.add(CUnknown("tRNS", trns));
		png.add(CData(f.data.getBytes()));
		png.add(CEnd);

		var bgra = Tools.extract32(png);
		var bmp = new BitmapData(f.width, f.height, true, 0);
		var ba = ByteArray.fromBytes(bgra);
		ba.endian = LITTLE_ENDIAN;
		bmp.setPixels(bmp.rect, ba);
		return bmp;
	}

	static function toDelayMs(num:Int, den:Int):Int
	{
		if (den == 0)
			den = 100;
		var ms = Math.round(1000 * num / den);
		return ms < 10 ? 10 : ms;
	}

	static function readInt(b:Bytes, pos:Int):Int
	{
		return (b.get(pos) << 24) | (b.get(pos + 1) << 16) | (b.get(pos + 2) << 8) | b.get(pos + 3);
	}

	static function readShort(b:Bytes, pos:Int):Int
	{
		return (b.get(pos) << 8) | b.get(pos + 1);
	}
}
