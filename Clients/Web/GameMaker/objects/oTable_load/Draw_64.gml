
tc=10
pc=300
sc=440
scd=465
pcc=260
pmc=360
cry=rectangle_y+50


draw_roundrect_colour(rectangle_x,rectangle_y,rectangle_x+rectangle_width,rectangle_y+rectangle_height,c_black,c_black,false);
draw_roundrect_colour(rectangle_x+5,rectangle_y+5,rectangle_x+rectangle_width-5,rectangle_y+45,c_navy,c_navy,false);

draw_set_halign(fa_left);
draw_set_font(fUI_Bold);
draw_set_colour(c_white);
draw_text(rectangle_x+tc, rectangle_y+12, "Table Name");
draw_text(rectangle_x+pc, rectangle_y+5, "Players");
draw_text(rectangle_x+sc, rectangle_y+12, "Status");
draw_text(rectangle_x+pcc, rectangle_y+19, "Current");
draw_text(rectangle_x+pmc, rectangle_y+19, "Max");

var colour = 16777215;
var record_num = 0;
repeat(7)
{
// Draw each game tables information 

draw_set_halign(fa_left);
draw_set_font(fUI_Normal);
draw_set_colour(c_black);
draw_roundrect_colour(rectangle_x+5,cry,rectangle_x+rectangle_width-5,cry+45,colour,colour,false);
draw_text(rectangle_x+tc, cry+15, table_name_array[record_num]);
draw_text(rectangle_x+pcc+30, cry+15, table_current_players_array[record_num]);
draw_text(rectangle_x+pmc+16, cry+15, table_max_players_array[record_num]);
draw_set_halign(fa_center);
draw_text(rectangle_x+scd, cry+15, table_status_array[record_num]);

// check if player has clicked into the table rectangle 
if (mouse_check_button_released(mb_left) && global.name_set == true && selectable[record_num]=true)
{ 
if (point_in_rectangle(mouse_x, mouse_y,rectangle_x+5,cry,rectangle_x+rectangle_width-5,cry+45))
{
    global.game_table_ID=table_id_array[record_num]
	join_table_url = BASE_URL + "/join?table=" + global.game_table_ID+"&player="+global.player_name
    http_request_join_table =http_get(join_table_url);
	http_request_table_list =http_get(TABLE_LIST_URL);
// need to add in some error checkign here 

} 
}


// increase to the next table row of data 
if colour== 16777215 then colour = 12632256 else colour = 16777215;
record_num++;
cry=cry+50;

}

// draw the name select stuff

draw_set_halign(fa_left);
draw_set_font(fUI_Normal);
draw_set_colour(c_black);
draw_text(12, 160, "Player Name:");
draw_text(12, 180, "then select a table to join from the list below");
draw_set_colour(c_white);
draw_roundrect(115,155,290,180,false);
draw_set_colour(c_red);
draw_text(120, 160, global.player_name);







