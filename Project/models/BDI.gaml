/***
* Name: BDI
* Author: vincent
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BDI

/* Insert your model definition here */

global {
	
	string empty_food_location <- "empty_food_location";
	string empty_bar_location <- "empty_bar_location";
	
	predicate is_eating <- new_predicate("is_eating");
	predicate is_drinking <- new_predicate("is_drinking");
	predicate is_dancing <- new_predicate("is_dancing");
	predicate is_socialising <- new_predicate("is_socialising");
	// predicate is_walking_to_target <- new_predicate("is_walking_to_target");
	
	
	predicate find_food <- new_predicate("find_food");
	predicate find_stage <- new_predicate("find_stage");
	predicate find_bar <- new_predicate("find_bar");
	predicate find_friend <- new_predicate("find_friend");
	
	predicate choose_stage <- new_predicate("choose_stage");
	predicate choose_food_truck <- new_predicate("choose_food_truck");
	predicate choose_bar <- new_predicate("choose_bar");
	
	predicate stage_location <- new_predicate("stage_location");
	predicate food_location <- new_predicate("food_location");
	predicate bar_location <- new_predicate("bar_location");
	
}

//give the simple_bdi architecture to the miner agents
species guest skills: [moving] control:simple_bdi {
	point target;
	float view_dist <- 100.0;
	
	init {
    	do add_desire(find_food);
    	do add_desire(find_stage);
    	do add_desire(find_bar);
    	do add_desire(find_friend);
    }
    
    // A function executed at each iteration to update the agent's Belief base, to know the 
    // changes in its environment (the world, the other agents and itself). The agent can 
    // perceive other agents up to a fixed distance or inside a specific geometry.
    perceive target: FoodTruck where (each.quantity > 0) in: view_dist {
    	
    	// - Iterating through all gold mines. var:location means we are looking at "location" 
    	// of each element in the array.
    	// - stage_location: name of the belief
    	// - stage_location.values (a map) will have "location" stored
	    focus id: food_location var:location;
	    ask myself {
	        do remove_intention(find_food, false);
	    }
    }
    
    rule belief: stage_location new_desire: is_dancing strength: 4.0;
    rule belief: food_location new_desire: is_eating strength: 3.0;
    rule belief: bar_location new_desire: is_drinking strength: 2.0;
    
    plan lets_wander intention: [find_friend, find_stage, find_bar, find_food] {
    	do wander;
    }
    
    plan get_food intention:is_eating {
	    if (target = nil) {
	        do add_subintention(get_current_intention(),choose_food_truck, true);
	        do current_intention_on_hold();
	    } else {
	        do goto target: target;
	        if (target = location)  { // If guest is at food store
		        FoodTruck current_food_truck <- FoodTruck first_with (target = each.location);
		        if current_food_truck.quantity > 0 {
		            do add_belief(is_eating);
		            ask current_food_truck {quantity <- quantity - 1;}    
		        } else {
		            do add_belief(new_predicate(empty_food_location, ["location_value"::target]));
		        }
		        target <- nil;
	        }
	    }   
    }
}


species Bar {
	
	int quantity <- 50;
	
	aspect base {
		draw triangle(5) color: #yellow;
	}
}

species FoodTruck {
	
	bool isVegan <- flip(0.5);
	int quantity <- 50;
	
	aspect base {
		draw triangle(5) color: isVegan ? #green : #red;
	}
}


