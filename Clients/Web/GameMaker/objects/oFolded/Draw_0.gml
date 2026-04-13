if (size == "Small")
{
	draw_sprite_ext(sFolded,0,x,y,0.65,0.50,0,c_white,1);
}
else
{
	draw_sprite_ext(sFolded,0,x,y,1,0.65,0,c_white,1);
}
size = "default"

instance_destroy(self);