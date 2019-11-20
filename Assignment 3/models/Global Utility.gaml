/***
* Name: GlobalUtility
* Author: vincent
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model GlobalUtility

/* Insert your model definition here */

global {
	
	list<Guest> guests;
	list<Stage> stages;
	list<Host> hosts;
	
	init {
		create Stage number:3 returns:_stages;
		create Guest number:10 returns:_guests;
		create Host number:1 returns: _hosts;
		hosts <- _hosts;
		stages <- _stages;
		guests <- _guests;
	}
}


species Guest skills: [fipa, moving] {
	
	float lightshow <- rnd(1, 10) / 10;
	float speakers <- rnd(1, 10) / 10;
	float band <- rnd(1, 10) / 10;
	float crowd_mass <- rnd(-10, 10) / 10;
	
	bool at_optimal_stage <- false;
	Stage optimal_stage <- nil;
	
	reflex read_inform_message when: !(empty(informs)) {		
		message inform <- informs at 0;
		do end_conversation with: [message :: inform, contents :: []];
		optimal_stage <- inform.contents[0];
		at_optimal_stage <- false;
	}
	
	reflex go_to_stage when: !at_optimal_stage and optimal_stage != nil {
		do goto target: optimal_stage.location;
		//write "Going to optimal stage! optimal_stage.location: " + optimal_stage.location + " location: " + location;
	}
	
	reflex reached_stage when: optimal_stage != nil and !at_optimal_stage and [optimal_stage] at_distance 3  {
		//write "Reached optimal stage! optimal_stage.location: " + optimal_stage.location + " location: " + location;
		at_optimal_stage <- true;
	}
	
	reflex dance when: at_optimal_stage {
		do wander;
	}
	
	aspect base {
		draw circle(1) color: (crowd_mass < 0) ? #red : #blue ;
	}
}


species Stage skills: [fipa] {
	
	float lightshow <- rnd(1, 10) / 10;
	float speakers <- rnd(1, 10) / 10;
	float band <- rnd(1, 10) / 10;
	float crowd_mass;
	
	reflex update_crowd_mass {
		crowd_mass <- length(Guest at_distance 4) / length(guests);
	}
	
	reflex start_new_concert when: flip(0.01) {
		lightshow <- rnd(1, 10) / 10;
		speakers <- rnd(1, 10) / 10;
		band <- rnd(1, 10) / 10;
		write name + ": New concert!";
		do start_conversation with: [ to :: hosts, protocol :: 'fipa-query', performative :: 'inform', contents :: [ ] ];
	}
	
	aspect base {
		draw square(5) color: #black;
	}
}

species Host skills: [fipa] {
	
	reflex inform_guests when: !empty(informs) {
		do end_conversation with: [message :: informs at 0, contents :: []];
		
		int s <- length(stages);
		int g <- length(guests);
		map<Guest, Stage> best_variation;
		float best_utility <- float(0);
		loop i from: 0 to: g ^ s - 1 {
			map<Guest, Stage> variation <- [];
			list<int> crowd <- list_with(s, 0);
			loop j from: 0 to: g - 1 {
				int si <- (i / (s ^ j)) mod s;
				crowd[si] <- crowd[si] + 1;
				add guests[j]::stages[si] to: variation;
			}
			
			float utility <- float(0);
			loop j from: 0 to: g - 1 {
				int si <- (i / (s ^ j)) mod s;
				utility <- utility + (
					stages[si].lightshow * guests[j].lightshow +
					stages[si].speakers * guests[j].speakers + 
					stages[si].band * guests[j].band +
					crowd[si] * guests[j].crowd_mass
				);
			}
			if (utility > best_utility) {
				best_variation <- variation;
				best_utility <- utility;
			}
		}
		
		write "Sending messages to guests";
		write "Global utility: " + best_utility;
		loop k over: best_variation.keys{
			do start_conversation with: [ to :: [k], protocol :: 'fipa-query', performative :: 'inform', contents :: [ best_variation[k] ] ];
		}
	}
}

experiment my_experiment type:gui {
	output {
		display my_display {
			species Guest aspect:base;
			species Stage aspect:base;
		}
	}
}