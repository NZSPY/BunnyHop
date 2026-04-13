/// @function                       draw_card_text(card number, card text, card size);
/// @param {int}    card number     The number to be draw on the card
/// @param {string}    card text    The text to be draw on the card
/// @param {string}    card size    The size the text on card should be drawn

function draw_card_text(argument0, argument1, argument2) 
{

	var _number = argument0;
	var _text = argument1;
	var _size = argument2;
	draw_set_colour(c_black);

	if (_size == "Small")

	{

	draw_set_font(fCard_Text_Small);
	draw_set_halign(fa_center);
	draw_text(x+28, y+66, _text);

	if (_number >0 and _number <9)
		{
		draw_set_font(fCard_Number_Small);
		draw_set_halign(fa_left);
		draw_text(x+2, y, _number);
		draw_text(x+42, y+58, _number);
		}

	}
	else
	{
	draw_set_font(fCard_Text_Big);
	draw_set_halign(fa_center);
	draw_text(x+35, y+90, _text);
	if (_number >0 and _number <9)
		{
		draw_set_font(fCard_Number_Big);
		draw_set_halign(fa_left);
		draw_text(x+4, y+2, _number);
		draw_text(x+58, y+80, _number);
		}
	}
}

