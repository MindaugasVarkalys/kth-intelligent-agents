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
		create store number:2 returns: newDrinkStores{
			isDrinkStore <- true;
		}
		create store number:2 returns: newFoodStores{
			isDrinkStore <- false;
		}
		create guest number:10;
		create information_center number:1{
			foodStores <- newFoodStores;
			drinkStores <- newDrinkStores;
		}
	}
}

species guest skills:[moving] {
	
	bool is_hungry <- flip(0.05);
	bool is_thirsty <- flip(0.05);
	bool knows_store_location <- false;
	point target <- nil;
		
	reflex moving when: target = nil {
		do wander;
	}
	
	reflex goingToStore when: !knows_store_location and (is_hungry or is_thirsty) and !empty(information_center at_distance 0) {
		
		ask information_center {
			
			if myself.is_hungry {
				int numFoodStores <- length(self.foodStores);
				write self.foodStores[rnd(numFoodStores-1)].location;
				myself.target <- self.foodStores[rnd(numFoodStores-1)].location;
				myself.knows_store_location <- true;
				
			} else if myself.is_thirsty {
				int numDrinkStores <- length(self.drinkStores);
				write self.drinkStores[rnd(numDrinkStores-1)].location;
				myself.target <- self.drinkStores[rnd(numDrinkStores-1)].location;
				myself.knows_store_location <- true;
			}
			
		}
		
	}
	
	reflex going_to_target when: target != nil {
		do goto target: target;
	}
	
	reflex going_to_information_center when: !knows_store_location and (is_hungry or is_thirsty) {
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
	list<store> drinkStores;
	list<store> foodStores;
	
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