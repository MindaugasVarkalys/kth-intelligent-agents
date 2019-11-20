/***
* Name: CreativeTask
* Author: vincent
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model CreativeTask

/* Insert your model definition here */

global {
	
	list<Guest> guests;
	list<Stage> stages;
	SafeSpot safe_spot;
	int GRID_SIZE <- 25;
	int exit_x <- rnd(3, GRID_SIZE-3);
	bool thunderstorm <- false;
	
	init {
		create Stage number:3 returns:_stages;
		create Guest number:50 returns:_guests;
		stages <- _stages;
		guests <- _guests;
		
		loop stage over: stages {
			cell single_cell <- cell grid_at {rnd(6,GRID_SIZE-6), rnd(6,GRID_SIZE-6)};
			stage.location <- single_cell.location;
		}
		
		create SafeSpot returns: _safe_spot;
		_safe_spot[0].location <- {0,0,0};
		safe_spot <- _safe_spot[0];
	}
	
	reflex weather_goes_bad when: flip(0.005) {
		thunderstorm <- true;
	}
	
	reflex weather_goes_good when: thunderstorm and flip(0.01) {
		thunderstorm <- false;
	}
}

grid cell width: GRID_SIZE height: GRID_SIZE neighbors: 4 {
    // rgb color <- (grid_x + grid_y) mod 2 = 0 ? #white : #black;
	bool is_border <- (
		((grid_x = 2 and grid_y < GRID_SIZE -2 and grid_y > 1 ) or
		(grid_x = GRID_SIZE -2 and grid_y < GRID_SIZE -2 and grid_y > 1 ) or
		(grid_y = 2 and grid_x < GRID_SIZE -2 and grid_x > 1 ) or
		(grid_y = GRID_SIZE -3 and grid_x < GRID_SIZE -2 and grid_x > 1 )) 
		and
		!(grid_x = exit_x)
	);
	
	rgb color <- is_border ? #black : #white;
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
		do goto target: optimal_stage.location on: (cell where not each.is_border);
		write "Going to optimal stage! optimal_stage.location: " + optimal_stage.location + " location: " + location;
	}
	
	
	reflex reached_stage when: optimal_stage != nil and [optimal_stage] at_distance 3 {
		write "Reached optimal stage! optimal_stage.location: " + optimal_stage.location + " location: " + location;
		at_optimal_stage <- true;
	}
	
	reflex dance when: at_optimal_stage {
		do wander; // bounds: (cell where not each.is_border); //on: (cell where not each.is_border);
	}
	
	reflex thunderstorm when: thunderstorm {
		do goto target: safe_spot.location on: (cell where not each.is_border);
		at_optimal_stage <- false;
		optimal_stage <- nil;
	}
	
	aspect base {
		draw circle(1) color: #red;
	}
}


species Stage skills: [fipa] {
	
	float lightshow <- rnd(1, 10) / 10;
	float speakers <- rnd(1, 10) / 10;
	float band <- rnd(1, 10) / 10;
	
	reflex start_new_concert when: flip(0.01) {
		lightshow <- rnd(1, 10) / 10;
		speakers <- rnd(1, 10) / 10;
		band <- rnd(1, 10) / 10;
		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [ self, lightshow, speakers, band ] ];
	}
	
	reflex reply_query_messages when: !(empty(queries)) {
		message queryFromInitiator <- queries at 0;
		write name + ' reads a query message with content : ' + (string(queryFromInitiator.contents));
		do agree with: [ message :: queryFromInitiator, contents :: ['OK, I will answer you'] ];
		do inform with: [ message :: queryFromInitiator, contents :: [ self, lightshow, speakers, band ] ];
	}
	
	aspect base {
		draw square(5) color: #black;
	}
}


species SafeSpot skills: [] {
	
	aspect base {
		draw square(20) color: #green;
	}
}



experiment my_experiment type:gui {
	output {
		display my_display {
			grid cell lines: #black;
			species SafeSpot aspect:base;
			species Guest aspect:base;
			species Stage aspect:base;
		}
	}
}