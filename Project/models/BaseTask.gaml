/***
* Name: BaseTask
* Author: minda
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BaseTask

/* Insert your model definition here */

global {
	
	list<string> genres <- ["POP", "Rock", "Deuche Rap", "Disco"];
	
	list<FoodTruck> foodTrucks;
	list<Bar> bars;
	
	init {
		create Stage number:3;
		create Guest number:50;
		create Bar number:3 returns: _bars;
		create FoodTruck number:5 returns: _foodTrucks;
		
		foodTrucks <- _foodTrucks;
		bars <- _bars;
	}
}


species Guest skills: [fipa, moving] {
	
	int happiness <- 50;
	point target <- nil;
		
	bool isVegan <- flip(0.3);
	int fullness <- rnd(1, 100);
	
	string favoriteGenre <- genres[rnd(0, length(genres) - 1)];
	
	reflex goingToTarget when: target != nil {
		do goto target: target;
	}
	
	reflex targetReached when: target - location = {0,0,0} {
		target <- nil;
	}
	
	reflex moveAround when: target = nil and flip(0.01) {
		target <- {rnd(100), rnd(100), 1};
	}
	
	reflex gettingHungry {
		fullness <- fullness - 1;
	}
	
	reflex gotHungry when: fullness = 0 {
		target <- foodTrucks[rnd(0, length(foodTrucks) - 1)].location;
	}
	
	reflex starving when: fullness < 0 {
		happiness <- happiness - 1;
	}
	
	reflex reachedFoodTruck when: !(empty(FoodTruck at_distance 0)) {
		if (FoodTruck at_distance 0)[0].isVegan = isVegan {
			int goodFoodHappiness <- (-rnd(500, 1500) / 1000) * fullness as int;
			happiness <- happiness + goodFoodHappiness;
			fullness <- 100;
			target <- {rnd(100), rnd(100), 1};
		} else {
			target <- foodTrucks[rnd(0, length(foodTrucks) - 1)].location;
		}
	}
	
	reflex dancing when: target = nil and !(empty(Stage at_distance 30)) {
		if (Stage at_distance 30)[0].genre = favoriteGenre {
			happiness <- happiness - 1;
		} else {
			happiness <- happiness + 3;
		}
		do wander;
	}
	
	reflex offersGoingTobBar when: target = nil and empty(Stage at_distance 30) {
		list<Guest> nearbyGuests <- Guest at_distance 10;
		Guest selectedGuest <- nearbyGuests[rnd(0, length(nearbyGuests) - 1)];
		if selectedGuest != nil {
			Bar selectedBar <- bars[rnd(0, length(bars) - 1)];
			do start_conversation with: [ to :: [selectedGuest], protocol :: 'fipa-query', performative :: 'propose', contents :: [favoriteGenre, selectedBar] ];
		}
	}
	
	reflex answerOffer when: !empty(proposes) {
		message proposal <- proposes at 0;
		if target != nil and proposal.contents[0] = favoriteGenre {
			do accept_proposal(message : proposal, contents : [] );
			target <- (proposal.contents[1] as Bar).location;
		} else {
			do reject_proposal(message : proposal, contents: [] );
		}
	}
	
	reflex enjoyBar when: !(empty(Bar at_distance 1)) {
		happiness <- happiness + 5;
	}
	
	aspect base {
		draw circle(1) color: rgb(0,0,255,happiness) border: #black;
	}
}

species Stage {
	
	string genre <- genres[rnd(0, length(genres) - 1)];
	
	reflex newConcert when: flip(0.05) {
		genre <- genres[rnd(0, length(genres) - 1)];
	}
	
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
			species Stage aspect:base;
			species Bar aspect:base;
			species FoodTruck aspect:base;
			species Guest aspect:base;
		}
	}
}