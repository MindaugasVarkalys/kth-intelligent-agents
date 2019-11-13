/***
* Name: Assignment2
* Author: minda
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BaseTask


/* Insert your model definition here */

global {
	init {
		create guest number:10;
	}
}

species guest skills:[moving] {

	reflex moving {
		do wander;
	}
	
	aspect base {
		draw circle(1) color: #black;
	}
}

experiment my_experiment type:gui {
	output {
		display my_display {
			species guest aspect:base;
		}
	}
}