/***
* Name: BDI
* Author: vincent
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BDI

/* Insert your model definition here */

global {
	
	init {
		create guest number: 1;
		create food_truck number: 5;
	}
	string food_location_name <- "food_location_name";
	
	predicate wander <- new_predicate("wander");
	predicate food_location <- new_predicate(food_location_name);
	predicate is_hungry <- new_predicate("is_hungry");
	predicate eat <- new_predicate("eat");
}

species guest skills: [moving] control:simple_bdi {
	bool is_vegan <- flip(0.5);
	
	float view_dist <- 10.0;
	point target;
	
	int fullness <- rnd(10, 1000);
	
	init {
    	do add_desire(wander);
    }
    
    perceive target: food_truck where (each.is_vegan = is_vegan) in: view_dist {
	    focus id: food_location_name var:location;
	    ask myself {
	    	if (fullness < 0) {
				do add_belief(is_hungry);
				do remove_intention(wander, false);
			}
	    }
    }
    
    perceive target: self {
    	if (fullness = 0) {
			list<point> food_locations <- get_beliefs_with_name(food_location_name) collect (point(get_predicate(mental_state (each)).values["location_value"]));
			write food_locations;
    		if (length(food_locations) > 0) {
    			do add_belief(is_hungry);
    			do remove_intention(wander, false);
    		}	
		}
		if (fullness >= 0) {
	    	fullness <- fullness - 1;
    	}
    }
    
    plan wander intention: wander {
    	do wander amplitude: 60.0;
    }
    
    rule belief: is_hungry new_desire: eat strength: 10.0;
    
    plan eat intention:eat {
	    if (target = nil) {
	        list<point> food_locations <- get_beliefs_with_name(food_location_name) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	        point nearest_location <- food_locations closest_to(self);
	        target <- nearest_location;
	    } else {
	        do goto target: target;
	        if (target = location) {
		        fullness <- 1000;
		        target <- nil;
		        do remove_belief(is_hungry);
		        do remove_intention(eat, true);
	        }
	    }   
    }
    
	aspect base {
		draw circle(1) color: rgb(0,0,255/* ,int(happiness * 2.55)*/) border: #black;
		draw circle(view_dist) color: rgb(255,0,0,100);
	}
}

species food_truck {
	
	bool is_vegan <- flip(0.5);
	
	aspect base {
		draw triangle(5) color: is_vegan ? #green : #red;
	}
}

experiment Bdi type: gui {
    output {
	    display map {
	        species food_truck aspect: base;
	        species guest aspect: base;
	    }
	}
}

