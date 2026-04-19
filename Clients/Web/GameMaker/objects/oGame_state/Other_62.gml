if (async_load[? "id"] == fetch_game_state)
{
if(ds_map_find_value(async_load,"status") == 0 )
	{
		var json =ds_map_find_value(async_load, "result");
		var data = json_parse(json);
		state_message = data.lmp;

		draw_deck = data.dd;
		discard_pile = data.dp;
		table_status = data.ts;
	 
		
			
// load game state information into game state arrays
var record_num=0;
var gotCat = false;
repeat(array_length(data.pls))
{
game_state_player_name[record_num] = data.pls[record_num].n;
game_state_player_status[record_num] = data.pls[record_num].s;
game_state_player_number_of_cards[record_num] = data.pls[record_num].nc;
game_state_player_hand_summary[record_num] = data.pls[record_num].ph;
game_state_player_valid_moves[record_num] = data.pls[record_num].pvm;
game_state_player_score[record_num]  = data.pls[record_num].sc;
game_state_player_has_cat[record_num]  = data.pls[record_num].hc;
game_state_player_winner[record_num]  = data.pls[record_num].win;



if game_state_player_name[record_num]==global.player_name then isPlayer = record_num;
if (game_state_player_has_cat[record_num])
{
	cat_status=record_num;
	gotCat=true;
}

record_num++;

if !gotCat then cat_status=7;

}
		
	}
	else
	{
	show_message("Lost conection to server");
	game_end();
		
	}
		
		
}