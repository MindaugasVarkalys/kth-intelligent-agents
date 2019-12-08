/***
* Name: BDI
* Author: vincent
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BDI

/* Insert your model definition here */

global {
	
	list<string> genres <- ["POP", "Rock", "Deuche Rap", "Disco"];
	list<stage> stages;
	
	init {
		create guest number: 1;
		create food_truck number: 5;
		create stage number: 3 returns: _stages;
		stages <- _stages;
	}
	string food_location_name <- "food_location";
	string stage_location_name <- "stage_location";
	
	predicate wander <- new_predicate("wander");
	predicate food_location <- new_predicate(food_location_name);
	predicate is_hungry <- new_predicate("is_hungry");
	predicate eat <- new_predicate("eat");
	
	predicate dance <- new_predicate("dance");
	predicate stage_location <- new_predicate(stage_location_name);
}

species guest skills: [moving] control:simple_bdi {
	string genre <- genres[rnd(0, length(genres) - 1)];
	bool is_vegan <- flip(0.5);
	
	float view_dist <- 10.0;
	point target;
	
	int fullness <- rnd(10, 1000);
	
	init {
    	do add_desire(wander);
    }
    
    perceive target: food_truck where (each.is_vegan = is_vegan) in: view_dist {
    	write "Food truck";
	    focus id: food_location_name var:location;
	    ask myself {
	    	do remove_intention(wander, fullness < 0);
	    }
    }
    
    perceive target: self {
    	write fullness;
    	if (fullness = 0) {
			do add_belief(is_hungry);
			do remove_intention(wander, true);
			do remove_intention(dance, false);
		}
		if (fullness >= 0) {
	    	fullness <- fullness - 1;
    	}
    }
    
    perceive target: stage where (each.genre = genre) {
    	focus id: stage_location_name var: location lifetime: 1;
    	write "Stage";
    	ask myself {
    		do remove_intention(wander, false);
    	}
    }
    
    rule belief: is_hungry new_desire: eat strength: 10.0;
    rule belief: stage_location new_desire: dance strength: 5.0;
    
    plan wander intention: wander {
    	do wander amplitude: 60.0;
    }
    
    plan eat intention:eat {
    	write "Eat";
	    if (target = nil) {
	        list<point> food_locations <- get_beliefs_with_name(food_location_name) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	        if (length(food_locations) > 0) {
	        	point nearest_location <- food_locations closest_to(self);
	        	target <- nearest_location;
	        } else {
	        	do add_subintention(get_current_intention(), wander, true);
				do current_intention_on_hold();
	        }
	    } else {
	        do goto target: target;
	        if (target = location) {
		        fullness <- 1000;
		        target <- nil;
		        do remove_belief(is_hungry);
		        do remove_intention(eat, true);
		        do add_desire(wander);        
	        }
	    }   
    }
    
    plan dance intention:dance {
    	if (target = nil) {
	        list<point> stage_locations <- get_beliefs_with_name(stage_location_name) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	        if (length(stage_locations) > 0) {
	        	write "Dance: new stage";
		        point nearest_location <- stage_locations closest_to(self);
		        target <- nearest_location;
	        } else {
	        	write "Dance: no stage";
	        	do remove_intention(dance, true);
	        	do add_desire(wander);
	        }
	    } else {
	    	stage target_stage <- stages first_with (target = each.location);
	    	if (target distance_to location > target_stage.radius) {
	    		do goto target: target;	
	    	} else {
	        	do wander;
		        target <- nil;
		        do remove_intention(dance, false);		        
	        }
	    }
    }
    
	aspect base {
		draw circle(1) color: rgb(0,0,255/* ,int(happiness * 2.55)*/) border: #black;
		//draw circle(view_dist) color: rgb(255,0,0,100);
	}
}

species food_truck {
	
	bool is_vegan <- flip(0.5);
	
	aspect base {
		draw triangle(5) color: is_vegan ? #green : #red;
	}
}

species stage {
	int radius <- rnd(10,20);
	string genre <- genres[rnd(0, length(genres) - 1)];
	
	reflex newConcert when: flip(0.01) {
		genre <- genres[rnd(0, length(genres) - 1)];
	}
	
	aspect base {
		draw square(5) color: #purple;
		draw circle(radius) color: rgb(#purple, 0.2);	
	}
}

experiment Bdi type: gui {
    output {
	    display map {
	        species food_truck aspect: base;
	        species stage aspect: base;
	        species guest aspect: base;
	    }
	}
}

