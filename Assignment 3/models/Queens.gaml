/***
* Name: Queens
* Author: minda
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Queens

/* Insert your model definition here */

global {
	int SIZE <- 10;
	init {
		queen parent;
		loop i from: 0 to: SIZE - 1 {
			create queen returns: column_queen {
				pred <- parent;
				location <- {0, 0, 0};
				col <- i;
			}
			parent <- column_queen[0];
		}
	}
}

grid chess_grid width: SIZE height: SIZE neighbors: 4 {
    rgb color <- (grid_x + grid_y) mod 2 = 0 ? #white : #black;
}


species queen skills: [moving] {
	
	bool positioned <- false;
	int row <- -1;
	int col;
	queen pred;
	
	bool is_right_position(chess_grid new_cell) {
		if (pred = nil) {
			return true;
		}
		return pred.row != new_cell.grid_y and
			abs(pred.row - new_cell.grid_y) != abs(pred.col - new_cell.grid_x) and 
			pred.is_right_position(new_cell);
	}
	
	reflex move_to_position when: !positioned and (pred = nil or pred.positioned = true) {
		if (row < SIZE - 1) {
			loop i from: (row + 1) to: SIZE - 1 {
				chess_grid cell <- chess_grid grid_at {col, i};
				location <- cell.location;
				
				if (is_right_position(cell)) {
					row <- i;
					write name + " " + row;
					positioned <- true;
					return;
				}
			}
		}
		row <- -1;
		location <- {0, 0, 0};
		write name + " " + row;
		pred.positioned <- false;
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