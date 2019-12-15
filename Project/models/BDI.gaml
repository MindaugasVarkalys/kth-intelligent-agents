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
	list<bar> bars;
	
	init {
		create guest number: 50;
		create food_truck number: 5;
		create stage number: 3 returns: _stages;
		create bar number: 3 returns: _bars;
		stages <- _stages;
		bars <- _bars;
	}
	string food_location_name <- "food_location";
	string stage_location_name <- "stage_location";
	string friend_name <- "friend";
	
	predicate wander <- new_predicate("wander");
	predicate food_location <- new_predicate(food_location_name);
	predicate is_hungry <- new_predicate("is_hungry");
	predicate eat <- new_predicate("eat");
	
	predicate dance <- new_predicate("dance");
	predicate stage_location <- new_predicate(stage_location_name);
	
	predicate friend <- new_predicate(friend_name);
	predicate invite_to_bar <- new_predicate("invite_to_bar");
	predicate go_to_bar <- new_predicate("go_to_bar");
}

species guest skills: [moving] control:simple_bdi {
	string genre <- genres[rnd(0, length(genres) - 1)];
	bool is_vegan <- flip(0.5);
	
	float view_dist <- 10.0;
	point target;
	
	int fullness <- rnd(10, 1000);
	int bar_time;
	
	init {
    	do add_desire(predicate: wander, strength: 1.0);
    }
    
    perceive target: food_truck where (each.is_vegan = is_vegan) in: view_dist {
    	write name + " Food truck";
	    focus id: food_location_name var:location;
    }
    
    perceive target: self {
    	write name + " " + fullness;
    	if (fullness = 0) {
			do add_belief(is_hungry);
			do remove_intention(wander, false);
			do remove_intention(go_to_bar, true);
			do remove_intention(dance, false);
		}
		if (fullness >= 0) {
	    	fullness <- fullness - 1;
    	}
    }
    
    perceive target: stage where (each.genre = genre) {
    	focus id: stage_location_name var: location lifetime: 1;
    	write name + " Stage";
    	ask myself {
    		do remove_intention(wander, false);
    	}
    }
    
    perceive target: guest where (each.genre = genre) in: view_dist {
    	focus id: friend_name var: location lifetime: 1;
    	float dist <- (location distance_to myself.location);
    	socialize liking: dist = 0 ? 1 : 1.0 / dist;
    }
    
    rule belief: is_hungry new_desire: eat strength: 10.0;
    rule belief: stage_location new_desire: dance strength: 5.0;
    rule belief: friend new_desire: invite_to_bar strength: 3.0;
     
    plan wander intention: wander {
    	write name + " wander";
    	do wander amplitude: 60.0;
    }
    
    plan eat intention:eat {
    	write name + " Eat";
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
	        }
	    }   
    }
    
    plan dance intention:dance {
    	write name + " dance";
    	if (target = nil) {
	        list<point> stage_locations <- get_beliefs_with_name(stage_location_name) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	        if (length(stage_locations) > 0) {
	        	write name + " Dance: new stage";
		        point nearest_location <- stage_locations closest_to(self);
		        target <- nearest_location;
	        } else {
	        	write name + " Dance: no stage";
	        	do remove_intention(dance, true);
	        }
	    } else {
	    	stage target_stage <- stages first_with (target = each.location);
	    	if (target_stage != nil) {
		    	if (target distance_to location > target_stage.radius) {
		    		do goto target: target;	
		    	} else {
		        	do wander;
			        target <- nil;
			    	do remove_intention(dance, false);    	        
		        }
	        } else {
	        	write name + " Dance but not a stage";
	        	do remove_intention(dance, false);	
	        }
	    }
    }
    
    plan invite_to_bar intention: invite_to_bar instantaneous: true {
    	write name + " invite to bar";
	    list<guest> my_friends <- list<guest>((social_link_base where (each.liking > 0.1)) collect each.agent);
	    point nearest_bar <- bars collect (each.location) closest_to(self);
	    int new_bar_time <- rnd(1, 10);
	    ask my_friends {
	    	if (target = nil) {
	    		write myself.name + " Inviting to bar " + name;
	    		do add_desire(predicate: go_to_bar, strength: 7.0);
	    		do remove_intention(dance, false);
	    		target <- nearest_bar;
	    		bar_time <- new_bar_time;
	    		ask myself {
	    			target <- nearest_bar;
	    			bar_time <- new_bar_time;
	    			do add_desire(predicate: go_to_bar, strength: 7.0);
	    		}
	    	}
    	}
    	do remove_intention(invite_to_bar, true);
    }
    
    plan go_to_bar intention: go_to_bar {
    	write name + " go to bar";
    	bar target_bar <- bars first_with (target = each.location);
	    if (target distance_to location > target_bar.radius) {
	    	write name + " going to bar";
	   		do goto target: target;
	    } else {
        	do wander;
	        if (bar_time > 0) {
	        	bar_time <- bar_time - 1;
	        	write name + " bar time: " + bar_time;
	        } else {
	        	target <- nil;
		        do remove_intention(go_to_bar, true);
	        }
        }
    }
    
	aspect base {
		draw circle(1) color: rgb(0,0,255/* ,int(happiness * 2.55)*/) border: #black;
		//draw circle(view_dist) color: rgb(255,0,0,100);
		draw name color: #black;
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

species bar {
	int radius <- 5;
	
	aspect base {
		draw triangle(5) color: #yellow;
		draw circle(radius) color: rgb(#purple, 0.2);
	}
}

experiment Bdi type: gui {
    output {
	    display map {
	        species food_truck aspect: base;
	        species stage aspect: base;
	        species guest aspect: base;
			species bar aspect: base;
	    }
	}
}

