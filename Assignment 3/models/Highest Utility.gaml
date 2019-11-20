/***
* Name: HighestUtility
* Author: vincent
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model HighestUtility

/* Insert your model definition here */

global {
	
	list<Guest> guests;
	list<Stage> stages;
	
	init {
		int NO_OF_GUESTS <- 10;
		int NO_OF_STAGES <- 3;
		create Stage number:3 returns:_stages;
		stages <- _stages;
		
		loop i from: 0 to: NO_OF_GUESTS {
			create Guest returns: guest {
//				float highestUtilityPerGuest;
//				write "Guest: lightshow: " + lightshow + " speakers: " + speakers + " band: " + band;
//				loop stage over: stages {
//					write "Stage: lightshow: " + stage.lightshow + " speakers: " + stage.speakers + " band: " + stage.band;
//					float utility <- (lightshow * stage.lightshow + speakers * stage.speakers + band * stage.band);
//					if utility > highestUtilityPerGuest {
//						highestUtilityPerGuest <- utility;
//						optimal_stage <- stage.location;
//						write "New Optimal Stage! lightshow: " + stage.lightshow + " speakers: " + stage.speakers + " band: " + stage.band;
//					}
//				}
			}
			guests <- guests + guest;
		}
		
	}
}


species Guest skills: [fipa, moving] {
	
	float lightshow <- rnd(1, 10) / 10;
	float speakers <- rnd(1, 10) / 10;
	float band <- rnd(1, 10) / 10;
	
	bool at_optimal_stage <- false;
	bool asked_all_stages <- false;
	Stage optimal_stage <- nil;
	
	reflex ask_preferences when: !asked_all_stages and !at_optimal_stage and optimal_stage = nil {
		do start_conversation with: [ to :: stages, protocol :: 'fipa-query', performative :: 'query', contents :: ['your attributes?'] ];
		asked_all_stages <- true;
	}
	
	reflex read_inform_message when: !(empty(informs)) {
		float highestUtility <- 0.0;
		write name + ' reads inform messages';
		if optimal_stage != nil {
			highestUtility <- (lightshow * optimal_stage.lightshow + speakers * optimal_stage.speakers + band * optimal_stage.band);
		}
		
		loop i over: informs {
			write 'inform message with content: ' + (string(i.contents));
			
			float utility <- (
				lightshow * float(i.contents[1]) +
				speakers * float(i.contents[2]) + 
				band * float(i.contents[3])
			);
			if utility > highestUtility {
				highestUtility <- utility;
				optimal_stage <- i.contents[0];
				write "New Optimal Stage! lightshow: " + optimal_stage.lightshow + " speakers: " + optimal_stage.speakers + " band: " + optimal_stage.band;
				at_optimal_stage <- false;
			}
		}
	}
	
	reflex go_to_stage when: !at_optimal_stage and optimal_stage != nil {
		do goto target: optimal_stage.location;
		write "Going to optimal stage! optimal_stage.location: " + optimal_stage.location + " location: " + location;
	}
	
	
	reflex reached_stage when: optimal_stage != nil and [optimal_stage] at_distance 3 {
		write "Reached optimal stage! optimal_stage.location: " + optimal_stage.location + " location: " + location;
		at_optimal_stage <- true;
	}
	
	reflex dance when: at_optimal_stage {
		do wander;
	}
	
	aspect base {
		draw circle(3) color: #red;
	}
}


species Stage skills: [fipa] {
	
	float lightshow <- rnd(1, 10) / 10;
	float speakers <- rnd(1, 10) / 10;
	float band <- rnd(1, 10) / 10;
	
	reflex start_new_concert when: flip(0.1) {
		lightshow <- rnd(1, 10) / 10;
		speakers <- rnd(1, 10) / 10;
		band <- rnd(1, 10) / 10;
		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [ self, lightshow, speakers, band ] ];
	}
	
	reflex reply_query_messages when: !(empty(queries)) {
		// loop i over: informs {
		message queryFromInitiator <- queries at 0;
		write name + ' reads a query message with content : ' + (string(queryFromInitiator.contents));
		do agree with: [ message :: queryFromInitiator, contents :: ['OK, I will answer you'] ];
		do inform with: [ message :: queryFromInitiator, contents :: [ self, lightshow, speakers, band ] ];
	}
	
	aspect base {
		draw square(5) color: #black;
//		if !in_auction {
//			draw square(5) color: #black;
//			return;
//		}
//		if item = "CDs" {
//			draw square(5) color: #red;
//		} else if item = "Shoes" {
//			draw square(5) color: #green;
//		} else if item = "T-Shirts" {
//			draw square(5) color: #blue;
//		}
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