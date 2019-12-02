/***
* Name: BDI
* Author: vincent
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BDI

/* Insert your model definition here */

global {
	predicate is_eating <- new_predicate("is_eating");
	predicate is_drinking <- new_predicate("is_drinking");
	predicate is_dancing <- new_predicate("is_dancing");
	predicate is_socialising <- new_predicate("is_socialising");
	// predicate is_walking_to_target <- new_predicate("is_walking_to_target");
	
	
	predicate find_food <- new_predicate("find_food");
	predicate find_stage <- new_predicate("find_stage");
	predicate find_bar <- new_predicate("find_bar");
	predicate find_friend <- new_predicate("find_friend");
	
	predicate stage_location <- new_predicate("stage_location");
	predicate food_location <- new_predicate("food_location");
	predicate bar_location <- new_predicate("bar_location");
	
}

//give the simple_bdi architecture to the miner agents
species guest skills: [moving] control:simple_bdi {
	point target;
	float view_dist <- 1000.0;
	
	init {
    	do add_desire(find_food);
    	do add_desire(find_stage);
    	do add_desire(find_bar);
    	do add_desire(find_friend);
    }
    
    // A function executed at each iteration to update the agent's Belief base, to know the 
    // changes in its environment (the world, the other agents and itself). The agent can 
    // perceive other agents up to a fixed distance or inside a specific geometry.
    perceive target: gold_mine where (each.quantity > 0) in: view_dist {
    	
    	// - Iterating through all gold mines. var:location means we are looking at "location" 
    	// of each element in the array.
    	// - mine_at_location: name of the belief
    	// - mine_at_location.values (a map) will have "location" stored
	    focus id: mine_at_location var:location;
	    ask myself {
	        do remove_intention(find_gold, false);
	    }
    }
    
    rule belief: stage_location new_desire: is_dancing strength: 2.0;
    rule belief: food_location new_desire: is_eating strength: 3.0;
    rule belief: drink_location new_desire: is_drinking strength: 3.0;
    
    plan lets_wander intention: [find_friend, find_stage, find_bar, find_food] {
    	do wander;
    }
}
