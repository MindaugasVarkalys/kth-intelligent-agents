/***
* Name: Queens
* Author: minda
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Queens

/* Insert your model definition here */

global {
	int SIZE <- 6;
	init {
		queen parent;
		loop i from: 0 to: SIZE - 1 {
			create queen returns: column_queen {
				positioning <- i = 0;
				predecessor <- parent;
				cell <- chess_grid grid_at {i, 0};
				location <- cell.location;
			}
			parent <- column_queen[0];
			write parent;
		}
	}
}

grid chess_grid width: SIZE height: SIZE neighbors: 4 {
    rgb color <- (grid_x + grid_y) mod 2 = 0 ? #white : #black;
}


species queen skills: [moving] {
	
	chess_grid cell;
	bool positioning;
	queen predecessor;
	
	bool is_right_position(chess_grid successor_cell) {
		return successor_cell.grid_x != cell.grid_x and predecessor.is_right_position(successor_cell);
	}
	
	reflex move_to_position when: positioning {
		loop i from: 0 to: SIZE - 1 {
			cell <- chess_grid grid_at {cell.grid_x, i};
			location <- cell.location;
		}
	}
	
	aspect base {
		draw circle(1) color: #red;	
	}
}

experiment my_experiment type:gui {
	output {
		display my_display {
			 grid chess_grid lines: #black;
			 species queen aspect:base;
		}
	}
}