switch (number)
{
	case 0:
		text="Dog";
	break;
	
	case 1:
		text = "Tomato";
	break;
	
	case 2:
		text = "Carrots";
	break;
	
	case 3:
		text = "Corn Cobs";
	break;
	
	case 4:
		text = "Lettuces";
	break;
	
	case 5:
		text = "Blue Peppers";
	break;

	case 6:
		text = "Eggplant";
	break;
	
	case 7:
		text = "Cauliflowers";
	break;
	
	case 8:
		text = "Beans";
	break;
	
	case 9:
		text = "Bunny";
	break;
}

if (size == "Small")
{
	draw_sprite_ext(sCard_Deck,number,x,y,0.15,0.15,0,c_white,1);
}
else if selected
{
	draw_sprite_ext(sCard_Deck,number,x,y,0.2,0.2,0,c_red,1);
}
else 
{
	draw_sprite_ext(sCard_Deck,number,x,y,0.2,0.2,0,c_white,1);
}

draw_card_text(number, text, size);

	

 instance_destroy(self);