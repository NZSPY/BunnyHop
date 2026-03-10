draw_set_halign(fa_left);
draw_set_font(fUI_Normal);
draw_set_colour(c_black);
draw_text(12, 160, "Player Name:");
draw_text(12, 180, "then select a table to join from the list below");
draw_set_colour(c_white);
draw_roundrect(115,155,290,180,false);
draw_set_colour(c_red);
draw_text(120, 160, global.player_name);


