
// Draw emply deck slot

draw_roundrect_colour(345,411,411,511,c_red,c_red,false);
draw_roundrect_colour(348,414,408,508,#42D2FF,#42D2FF,false);


// Draw Player grid area
draw_roundrect_colour(5,185,330,735,c_green,c_green,false);
draw_roundrect_colour(10,191,325,728,c_blue,c_blue,false);

sloty=295;
repeat(4)
{
draw_line_width_colour(10,sloty,325,sloty,8,c_green,c_green);
sloty=sloty+110;
}

slotx = 15;
sloty = 160;

draw_set_halign(fa_left);
draw_set_font(fUI_Normal);
draw_set_colour(c_white);


draw_text(slotx, sloty,state_message);

draw_text(slotx, sloty+24,discard_pile);
draw_text(slotx, sloty+36,table_status);


sloty=195;

var record_num = 0;



repeat(6)
{
// Draw each players state information 

if (game_state_player_name[record_num] <> "" && isPlayer<>record_num)
{
draw_text(slotx, sloty,game_state_player_name[record_num] );
// draw_text(slotx, sloty+12, game_state_player_status[record_num]);
// draw_text(slotx, sloty+24, game_state_player_number_of_cards[record_num]);
// draw_text(slotx, sloty+36, game_state_player_hand_summary[record_num]);
// draw_text(slotx, sloty+48, game_state_player_valid_moves[record_num]);
sloty=sloty+110;
}

if (record_num=isPlayer) 
{
	draw_text(slotx, 750,game_state_player_name[record_num] );
}
record_num++;

}

// Draw the Draw deck if the table satus is playing and deck has cards left
if (table_status= 3 && draw_deck > 0) 
{
draw_sprite_ext(sCardBack,0,342,410,0.2,0.2,0,c_white,1);
draw_set_halign(fa_left);
draw_set_font(fUI_Bold);
draw_set_colour(c_white);
draw_text(378, 520,draw_deck);

}

