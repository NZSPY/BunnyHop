if (mouse_check_button_released(mb_left))
{ 
if (point_in_rectangle(mouse_x, mouse_y,115,155,290,180))
{

	msg = get_string_async("What's your name?", "Lorenzo");
	global.name_set = true

} 
}


	
if (string_length(global.player_name) > 10 && global.name_set)
{
    global.player_name = string_copy(global.player_name, 1, 10);
}

/*
var inst1 = instance_create_depth(20,650,-10,oCard); with (inst1)  {number = 1; size  = "Small";}
var inst2 = instance_create_depth(80,650,-10,oCard); with (inst2) {number = 2; size  = "Small";}
var inst3 = instance_create_depth(140,650,-10,oCard); with (inst3) {number = 3; size  = "Small";}
var inst4 = instance_create_depth(200,650,-10,oCard); with (inst4) {number = 4; size  = "Small";}
var inst5 = instance_create_depth(260,650,-10,oCard); with (inst5) {number = 5; size  = "Small";}
var inst6 = instance_create_depth(320,650,-10,oCard); with (inst6) {number = 6; size  = "Small";}
var inst7 = instance_create_depth(380,650,-10,oCard); with (inst7) {number = 7; size  = "Small";}
var inst8 = instance_create_depth(440,650,-10,oCard); with (inst8) {number = 8; size  = "Small";}


var big1 = instance_create_depth(20,750,-10,oCard); with (big1) {number = 1; size  = "Big";}
var big2 = instance_create_depth(100,750,-10,oCard); with (big2) {number = 2; size  = "Big";}
var big3 = instance_create_depth(180,750,-10,oCard); with (big3) {number = 3; size  = "Big";}
var big4 = instance_create_depth(260,750,-10,oCard); with (big4) {number = 4; size  = "Big";}
var big5 = instance_create_depth(340,750,-10,oCard); with (big5) {number = 5; size  = "Big";}
var big6 = instance_create_depth(420,750,-10,oCard); with (big6) {number = 6; size  = "Big";}
var big7 = instance_create_depth(20,860,-10,oCard); with (big7) {number = 7; size  = "Big";}
var big8 = instance_create_depth(100,860,-10,oCard); with (big8) {number = 8; size  = "Big";}

var big0 = instance_create_depth(180,860,-10,oCard); with (big0) {number = 0; size  = "Big";}
var big9 = instance_create_depth(260,860,-10,oCard); with (big9) {number = 9; size  = "Big";}
var big10 = instance_create_depth(340,860,-10,oCard); with (big10) {number = 10; size  = "Big";}
*/
