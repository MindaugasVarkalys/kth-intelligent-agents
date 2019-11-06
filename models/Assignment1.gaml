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
		create store number:2{
			isDrinkStore <- true;
		}
		create store number:2{
			isDrinkStore <- false;
		}
		create guest number:10;
		create information_center number:1;
	}
}

species guest skills:[moving] {
	
	bool is_hungry <- flip(0.05);
	bool is_thirsty <- flip(0.05);
	point target <- nil;
		
	reflex moving when: target = nil {
		do wander;
	}
	
	reflex going_to_target when: target != nil {
		do goto target: target;
	}
	
	reflex going_to_information_center when: is_hungry or is_thirsty {
		ask information_center {
			myself.target <- self.location;
		}
	}
	
	reflex getting_hungry when: !is_hungry and !is_thirsty {
		is_hungry <- flip(0.05);
	}
	
	reflex getting_thirsty when: !is_hungry and !is_thirsty {
		is_thirsty <- flip(0.05);
	}
	
	aspect base {
		rgb state_color <- #black;
		if (is_thirsty) {
			state_color <- #orange;	
		} else if (is_hungry) {
			state_color <- #blue;
		}
		draw circle(1) color: state_color;
	}
}

species information_center {
	aspect base {
		draw square(5) color: #yellow;
	}
}

species store {
	bool isDrinkStore;
	
	aspect base {
		draw square(5) color: (isDrinkStore) ? #green : #red;
	}
}

experiment my_experiment type:gui {
	output {
		display my_display {
			species guest aspect:base;
			species information_center aspect:base;
			species store aspect:base;
		}
	}
}