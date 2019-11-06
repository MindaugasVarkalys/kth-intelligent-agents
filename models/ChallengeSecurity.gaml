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
		create guest number:9 {
			is_bad <- false;
		}
		create guest number:1 {
			is_bad <- true;
		}
		create guard number:1;
		create information_center number:1{
			foodStores <- newFoodStores;
			drinkStores <- newDrinkStores;
		}
	}
}

species guest skills:[moving] {
	bool is_hungry <- flip(0.01);
	bool is_thirsty <- flip(0.01);
	bool is_bad;
	point drinkStoreLocation;
	point foodStoreLocation;
	
	point target <- nil;
		
	reflex moving when: target = nil {
		do wander;
	}
	
	reflex getting_hungry when: !is_hungry and !is_thirsty and target = nil {
		is_hungry <- flip(0.01);
	}
	
	reflex getting_thirsty when: !is_hungry and !is_thirsty and target = nil {
		is_thirsty <- flip(0.01);
	}
	
	reflex going_to_target when: target != nil {
		do goto target: target;
	}
	
	reflex got_hungry_or_thirsty when: (is_hungry or is_thirsty) and target = nil {
		if (is_hungry and foodStoreLocation != nil) {
			target <- foodStoreLocation;
		} else if (is_thirsty and drinkStoreLocation != nil) {
			target <- drinkStoreLocation;
		} else {
			ask information_center {
				myself.target <- self.location;
			}
		}
	}
	
	reflex reached_info_center when: (is_hungry or is_thirsty) and !empty(information_center at_distance 0) {
		ask information_center {
			if myself.is_hungry {
				int numFoodStores <- length(self.foodStores);
				myself.foodStoreLocation <- self.foodStores[rnd(numFoodStores-1)].location; 
				myself.target <- myself.foodStoreLocation;
			} else if myself.is_thirsty {
				int numDrinkStores <- length(self.drinkStores);
				myself.drinkStoreLocation <- self.drinkStores[rnd(numDrinkStores-1)].location;
				myself.target <- myself.drinkStoreLocation;
			}
		}
	}
	
	reflex reached_store when: (is_hungry or is_thirsty) and !empty(store at_distance 0) {
		is_hungry <- false;
		is_thirsty <- false;
		target <- {rnd(100), rnd(100), 1};
	}
	
	reflex reached_target when: target - location = {0,0,0} {
		target <- nil;
	}

	aspect base {
		rgb state_color <- #black;
		if (is_bad) {
			state_color <- #purple;
		} else if (is_thirsty) {
			state_color <- #green;	
		} else if (is_hungry) {
			state_color <- #red;
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
	
	reflex bad_guest when: !empty((guest where (each.is_bad = true)) at_distance 0) {
		list<guest> bad_guests <- guest where (each.is_bad = true) at_distance 0;
		ask guard {
			self.targets <<+ bad_guests;
		}
	}
}

species guard skills:[moving] {
	list<guest> targets <- [];
	
	reflex going_to_target when: length(targets) > 0 {
		do goto target: targets[0].location;
	}
	
	reflex kill_target when: length(targets) > 0 and location distance_to targets[0].location = 0 {
		ask targets[0] {
			do die;
		}
		targets[] >- 0;
	} 
	
	aspect base {
		draw triangle(3) color: #purple;
	}
}

experiment my_experiment type:gui {
	output {
		display my_display {
			species guest aspect:base;
			species information_center aspect:base;
			species store aspect:base;
			species guard aspect:base;
		}
	}
}