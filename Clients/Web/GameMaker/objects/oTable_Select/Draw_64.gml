rx=10
ry=205
rw=520
rh=400
tc=10
pc=300
sc=440
scd=465
pcc=260
pmc=360
cry=ry+50


draw_roundrect_colour(rx,ry,rx+rw,ry+rh,c_black,c_black,false);
draw_roundrect_colour(rx+5,ry+5,rx+rw-5,ry+45,c_navy,c_navy,false);

draw_set_halign(fa_left);
draw_set_font(fUI_Bold);
draw_set_colour(c_white);
draw_text(rx+tc, ry+12, "Table Name");
draw_text(rx+pc, ry+5, "Players");
draw_text(rx+sc, ry+12, "Status");
draw_text(rx+pcc, ry+19, "Current");
draw_text(rx+pmc, ry+19, "Max");

var colour = 16777215;
var array_step = 0;
repeat(7)
{
draw_set_halign(fa_left);
draw_set_font(fUI_Normal);
draw_set_colour(c_black);
draw_roundrect_colour(rx+5,cry,rx+rw-5,cry+45,colour,colour,false);
draw_text(rx+tc, cry+15, table_name_array[array_step]);
draw_text(rx+pcc+30, cry+15, table_current_players_array[array_step]);
draw_text(rx+pmc+16, cry+15, table_max_players_array[array_step]);
draw_set_halign(fa_center);
draw_text(rx+scd, cry+15, table_status_array[array_step]);
if colour= 16777215 then colour = 12632256 else colour = 16777215;
array_step++;
cry=cry+50;
}






