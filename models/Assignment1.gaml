/***
* Name: NewModel
* Author: vincent
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Assignment1


/* Insert your model definition here */

global {
	init {
		create guest number:10;
		create information_center number:1;
	}
}

species guest skills:[moving] {	
	reflex moving {
		do wander;
	}
	
	aspect base {
		draw circle(1) color: #red;
	}
}

species information_center {
	aspect base {
		draw square(10) color: #yellow;
	}
}

experiment my_experiment type:gui {
	output {
		display my_display {
			species guest aspect:base;
			species information_center aspect:base;
		}
	}
}