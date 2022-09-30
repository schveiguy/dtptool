import raylib;
import std.stdio;
import std.conv : mktxt = text;

enum textheight = 20;
enum borderwidth = 2;

GuiElement[] elements;

abstract class GuiElement {
	Rectangle extents;
	Color color;

	this(int x, int y, int width, int height, Color color)
	{
		this.extents = Rectangle(x, y, width, height);
		this.color = color;
	}

	abstract void draw();

	final bool contains(Vector2 pt)
	{
		return CheckCollisionPointRec(pt, extents);
	}

	void tick() {}
}

class Label : GuiElement {

	protected string _text;

	this(Args...)(int x, int y, Color color, Args initialText)
	{
		super(x, y, 0, textheight, color);
		this.setText(initialText);
	}

	override void draw()
	{
		DrawText(_text.ptr, cast(int)extents.x, cast(int)extents.y, textheight, color);
	}

	void setText(Args...)(Args args)
	{
		this._text = mktxt(args, "\0");
		textWasSet();
	}

	void textWasSet()
	{
		extents.width = MeasureText(_text.ptr, textheight);
	}

	string text() { return _text[0 .. $-1];}
}

class Button : Label {
	bool pushed;
	bool highlight;
	int textwidth;
	int repeatCountdown;
	bool allowRepeat;
	void delegate() clicked;

	this(Args...)(void delegate() clicked, int x, int y, Color color, Args initialText)
	{
		super(x, y, color, initialText);
		extents.height = textheight + (borderwidth+3)*2;
		extents.width = textwidth + (borderwidth+3)*2;
		this.clicked = clicked;
	}

	this(Args...)(void delegate() clicked, int x, int y, int width, int height, Color color, Args initialText)
	{
		super(x, y, color, initialText);
		extents.height = height;
		extents.width = width;
		this.clicked = clicked;
	}

	override void textWasSet()
	{
		textwidth = MeasureText(_text.ptr, textheight);
	}

	override void draw()
	{
		auto ex = extents;
		if(highlight)
			DrawRectangleRec(ex, color);
		else
			DrawRectangleLinesEx(ex, borderwidth, color);
		// center the text
		DrawText(_text.ptr, cast(int)(ex.x + (ex.width - textwidth)/2),
		                    cast(int)(ex.y + (ex.height - textheight)/2),
							textheight,
							highlight ? Colors.WHITE : color);
	}

	override void tick() {
		if(pushed)
		{
			if(IsMouseButtonReleased(MouseButton.MOUSE_BUTTON_LEFT))
			{
				if(repeatCountdown >= 0 && contains(GetMousePosition))
				{
					if(clicked) clicked();
				}
				pushed = false;
			}
		}
		else if(IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT))
		{
			if(contains(GetMousePosition))
			{
				pushed = true;
				repeatCountdown = 20;
			}
		}

		highlight = pushed && contains(GetMousePosition);
		if(allowRepeat && highlight && --repeatCountdown < -2)
		{
			// repeating
			repeatCountdown = -1;
			if(clicked) clicked();
		}
	}
}

Button repeater(Button btn) { btn.allowRepeat = true; return btn;}

float right(ref Rectangle rec) { return rec.x + rec.width; }
float bottom(ref Rectangle rec) { return rec.y + rec.height; }

void main()
{
	InitWindow(1000, 800, "Texture Demo");
	SetTargetFPS(60);

	auto texture = LoadTexture("testTexture.png");
	//texture.width *= 4;
	//texture.height *= 4;
	scope(exit) UnloadTexture(texture);

	// void DrawTexturePro(Texture2D texture, Rectangle source, Rectangle dest, Vector2 origin, float rotation, Color tint);
	Rectangle source = Rectangle(0, 0, texture.width, texture.height);
	Rectangle dest = Rectangle(0, 0, texture.width, texture.height);
	Vector2 origin = Vector2(0, 0);
	float rotation = 0;
	Color tint = Colors.WHITE;

	enum sourcecolor = Colors.RED;
	enum destcolor = Colors.PURPLE;
	enum origincolor = Colors.GOLD;

	GuiElement[] elements;
	int lastx() { return cast(int)elements[$-1].extents.x;}
	int nextx() { return cast(int)elements[$-1].extents.right + 5;}
	int lasty() { return cast(int)elements[$-1].extents.y;}
	int nexty() { return cast(int)elements[$-1].extents.bottom + 3;}
	void editItem(alias textupdator, T)(T* item, string itemName, int x, int y)
	{
		// add the - button
		elements ~= new Label(x, y, Colors.BLACK, itemName);
		auto label = elements[$-1];
		elements ~= new Button({
			*item += 1;
			textupdator();
		}, nextx, y, Colors.BLUE, "+").repeater;
		elements ~= new Button({
			*item -= 1;
			textupdator();
		}, nextx, y, Colors.BLUE, "-").repeater;

		// center the label
		label.extents.y = elements[$-1].extents.y + (elements[$-1].extents.height - label.extents.height) / 2;
	}

	// source
	Label sourceLabel = new Label(500, 10, sourcecolor);
	void updateSource()
	{
		sourceLabel.setText("source: (x:", source.x, ", y:", source.y, ", w:", source.width, ", h:", source.height, ")");
	}
	elements ~= sourceLabel;
	editItem!updateSource(&source.x, "x", 500, nexty);
	editItem!updateSource(&source.y, "y", nextx + 10, lasty);
	editItem!updateSource(&source.width, "width", nextx + 10, lasty);
	editItem!updateSource(&source.height, "height", nextx + 10, lasty);
	updateSource();

	// dest
	Label destLabel = new Label(500, nexty, destcolor);
	void updateDest() {
		destLabel.setText("dest: (x:", dest.x, ", y:", dest.y, ", w:", dest.width, ", h:", dest.height, ")");
	}
	elements ~= destLabel;
	editItem!updateDest(&dest.x, "x", 500, nexty);
	editItem!updateDest(&dest.y, "y", nextx + 10, lasty);
	editItem!updateDest(&dest.width, "width", nextx + 10, lasty);
	editItem!updateDest(&dest.height, "height", nextx + 10, lasty);
	updateDest();

	// origin
	Label originLabel = new Label(500, nexty, origincolor);
	void updateOrigin() {
		originLabel.setText("origin: (x:", origin.x, ", y:", origin.y, ")");
	}
	elements ~= originLabel;
	editItem!updateOrigin(&origin.x, "x", 500, nexty);
	editItem!updateOrigin(&origin.y, "y", nextx + 10, lasty);
	updateOrigin();

	// rotation
	Label rotationLabel = new Label(500, nexty, Colors.BLACK);
	void updateRotation() {
		rotationLabel.setText("rotation: ", rotation, " degrees");
	}
	elements ~= rotationLabel;
	editItem!updateRotation(&rotation, "degrees", 500, nexty);
	updateRotation();

	// tint
	Label tintLabel = new Label(500, nexty, Colors.BLACK);
	void updateTint() {
		tintLabel.setText("tint: (r:", tint.r, ", g:", tint.g, ", b:", tint.b, ", a:", tint.a, ")");
	}
	elements ~= tintLabel;
	editItem!updateTint(&tint.r, "red", 500, nexty);
	editItem!updateTint(&tint.g, "green", nextx + 10, lasty);
	editItem!updateTint(&tint.b, "blue", nextx + 10, lasty);
	editItem!updateTint(&tint.a, "alpha", nextx + 10, lasty);
	updateTint();

	auto previewtop = nexty;
	auto previewleft = 500;

	while(!WindowShouldClose())
	{
		foreach(e; elements)
			e.tick;
		BeginDrawing();
		ClearBackground(Colors.WHITE);
		foreach(e; elements)
			e.draw;

		{
			rlPushMatrix();
			scope(exit) rlPopMatrix();
			rlTranslatef(previewleft, previewtop, 0);

			// draw the texture source
			DrawRectangle(0, 0, GetScreenWidth, GetScreenHeight, Color(150, 150, 150, 255));
			DrawText("Texture:", 0, 0, textheight, Colors.BLACK);
			rlTranslatef((GetScreenHeight - previewtop - texture.height) / 2,
						(GetScreenWidth - previewleft - texture.width) / 2, 0);
			DrawTexture(texture, 0, 0, Colors.WHITE);
			// draw the source rectangle
			auto previewsource = source;
			// normalize the rectangle
			with(previewsource) if(width < 0)
			{
				x += width;
				width = -width;
			}
			with(previewsource) if(height < 0)
			{
				y += height;
				height = -height;
			}
			DrawRectangleLinesEx(previewsource, 1, sourcecolor);
			// draw the origin as a dot
			auto previeworigin = origin;
			previeworigin.x *= (source.width / dest.width);
			previeworigin.y *= (source.height / dest.height);
			previeworigin += Vector2(source.x, source.y);
			DrawCircleV(previeworigin, 3, origincolor);
		}
		DrawRectangle(0, 0, 500, GetScreenHeight, Color(200, 200, 200, 255));
		{
			rlPushMatrix();
			scope(exit) rlPopMatrix();
			DrawTexturePro(texture, source, dest, origin, rotation, tint);
			DrawCircleV(Vector2(dest.x, dest.y), 3, Colors.GOLD);
			auto previewdest = dest;
			previewdest.x -= origin.x;
			previewdest.y -= origin.y;

			rlTranslatef(dest.x, dest.y, 0);
			rlRotatef(rotation, 0, 0, 1);
			rlTranslatef(-dest.x, -dest.y, 0);
			DrawRectangleLinesEx(previewdest, 1, destcolor);
		}
		EndDrawing();
	}
	CloseWindow();
}