http_request_game_state_URL = BASE_URL +"/state?table="+global.game_table_ID+"&player="+global.player_name;
http_request_game_start_URL = BASE_URL +"/start?table="+global.game_table_ID;
http_request_Do_Move_URL = BASE_URL +"/move?table="+global.game_table_ID+"&player="+global.player_name+"&VM=";

state_message = "" ;
draw_deck = "";
discard_pile = "";
table_status= "";
cat_status="B"; // cat is in the basket 
game_state_player_name = array_create(7);
game_state_player_status = array_create(7);
game_state_player_number_of_cards = array_create(7);
game_state_player_hand_summary = array_create(7);
game_state_player_valid_moves = array_create(7);
display_player_card = array_create(70);

// display_other_player_card = array_create(70);
// player_card_index=0;

isPlayer = 0;

slotx = 10;
sloty = 160;

fetch_game_state=http_get(http_request_game_state_URL);


alarm[0] = game_get_speed(gamespeed_fps) * 10;
var record_num = 0;
repeat(7)
{
game_state_player_name[record_num] = "";
game_state_player_status[record_num] = "";
game_state_player_number_of_cards[record_num] = "";
game_state_player_hand_summary[record_num] = "";
game_state_player_valid_moves[record_num] = "";
record_num++;
}

size = "default"
number = 10