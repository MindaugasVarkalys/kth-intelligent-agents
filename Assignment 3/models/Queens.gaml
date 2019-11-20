/***
* Name: Queens
* Author: minda
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Queens

/* Insert your model definition here */

grid chess_grid width: 6 height: 6 neighbors: 4 {
    rgb color <- (grid_x + grid_y) mod 2 = 0 ? #white : #black;
}


experiment my_experiment type:gui {
	output {
		display my_display {
			 grid chess_grid lines: #black ;
		}
	}
}