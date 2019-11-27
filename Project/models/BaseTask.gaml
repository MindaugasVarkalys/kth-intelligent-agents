/***
* Name: BaseTask
* Author: minda
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BaseTask

/* Insert your model definition here */

global {
	
	list<FoodTruck> foodTrucks;
	
	init {
		create Stage number:3;
		create Guest number:50;
		create Bar number:3;
		create FoodTruck number:5 returns: _foodTrucks;
		
		foodTrucks <- _foodTrucks;
	}
}


species Guest skills: [fipa, moving] {
	
	bool isVegan <- flip(0.3);
	int fullness <- rnd(1, 100);
	int happiness <- 50;
	point target <- nil;
	
	reflex dancing when: target = nil {
		do wander;
	}
	
	reflex goingToTarget when: target != nil {
		do goto target: target;
	}
	
	reflex targetReached when: target - location = {0,0,0} {
		target <- nil;
	}
	
	reflex gettingHungry {
		fullness <- fullness - 1;
	}
	
	reflex gotHungry when: fullness = 20 {
		target <- foodTrucks[rnd(0, length(foodTrucks) - 1)].location;
	}
	
	reflex starving when: fullness < 20 {
		happiness <- happiness - 1;
	}
	
	reflex reachedFoodTruck when: !(empty(FoodTruck at_distance 0)) {
		if (FoodTruck at_distance 0)[0].isVegan = isVegan {
			fullness <- 100;
			target <- {rnd(100), rnd(100), 1};	
		} else {
			target <- foodTrucks[rnd(0, length(foodTrucks) - 1)].location;
		}
	}
	
	aspect base {
		draw circle(1) color: #blue;
	}
}

species Stage {
	aspect base {
		draw square(8) color: #purple;
	}
}

species Bar {
	
	aspect base {
		draw triangle(5) color: #yellow;
	}
}

species FoodTruck {
	
	bool isVegan <- flip(0.5);
	
	aspect base {
		draw triangle(5) color: isVegan ? #green : #red;
	}
}


experiment my_experiment type:gui {
	output {
		display my_display {
			species Guest aspect:base;
			species Stage aspect:base;
			species Bar aspect:base;
			species FoodTruck aspect:base;
		}
	}
}