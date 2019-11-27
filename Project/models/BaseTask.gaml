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
	list<Guest> guests;
	
	init {
		create Stage number:3;
		create Guest number:30 returns: _guests;
		create Bar number:3 returns: _bars;
		create FoodTruck number:5 returns: _foodTrucks;
		
		guests <- _guests;
		foodTrucks <- _foodTrucks;
		bars <- _bars;
	}
}


species Guest skills: [fipa, moving] {
	
	int happiness <- 50;
	agent target <- nil;
	bool isVegan <- flip(0.3);
	int fullness <- rnd(1, 100);
	int starvingLevel <- 20;
	string favoriteGenre <- genres[rnd(0, length(genres) - 1)];
	
	reflex equalifyValues {
		if happiness < 0 {
			happiness <- 0;
		} else if happiness > 100 {
			happiness <- 100;
		}
	}
	
	reflex printing {
		write 
			"name" + name + 
			", happiness: " + happiness +
			", target: " + target +
			", fullness: " + fullness +
			", favoriteGenre: " + favoriteGenre
			;
	}
	
	reflex goingToTarget when: target != nil {
		do goto target: target;
	}
	
	reflex targetReached when: target != nil {
		if (target is Stage and !(empty([target] at_distance 5))) or (target.location - location = {0,0,0}) {
			target <- nil;
		}	
	}
	
	reflex moveAround when: target = nil and flip(0.5) {
		// target.location <- {rnd(100), rnd(100), 1};
	}
	
	reflex gettingHungry {
		fullness <- fullness - 1;
	}
	
	reflex starving when: fullness < starvingLevel {
		happiness <- happiness - 1;
		if !(target is FoodTruck) {
			target <- foodTrucks[rnd(0, length(foodTrucks) - 1)];
		}
	}
	
	reflex reachedFoodTruck when: !(empty(FoodTruck at_distance 0)) {
		if (FoodTruck at_distance 0)[0].isVegan = isVegan {
			// int goodFoodHappiness <- (rnd(50, 100)) * fullness as int;
			// write "goodFoodHappiness: " + goodFoodHappiness;
			// happiness <- happiness + goodFoodHappiness;
			happiness <- happiness + 20;
			write "New happiness: " + happiness;
			fullness <- 100;
			target <- nil;
		} else {
			target <- foodTrucks[rnd(0, length(foodTrucks) - 1)];
		}
	}
	
	reflex dancing when: target = nil and !(empty(Stage at_distance 20)) {
		loop stage over: Stage at_distance 20 {
			if stage.genre = favoriteGenre {
				write "At favourite stage";
				happiness <- happiness + 20;
				do wander;
				return;
			}
		}
		write "Near stage, but not dancing. Target: " + target;
	}
	
	reflex offersGoingToBar when: target = nil and empty(Stage at_distance 20) and !empty(Guest at_distance 5) {
		list<Guest> nearbyGuests <- Guest at_distance 5;
		Guest selectedGuest <- nearbyGuests[rnd(0, length(nearbyGuests) - 1)];
		Bar selectedBar <- bars[rnd(0, length(bars) - 1)];
		do start_conversation with: [ to :: [selectedGuest], protocol :: 'fipa-query', performative :: 'propose', contents :: [favoriteGenre, selectedBar] ];
	}
	
	reflex PersonAcceptedBarOffer when: !empty(accept_proposals) {
		message accept_proposal <- accept_proposals at 0;
		Bar proposedBar <- accept_proposal.contents[0];
		target <- proposedBar;
		happiness <- happiness + 30;
	}
	
	reflex PersonDeclinedBarOffer when: !empty(reject_proposals) {
		message reject_proposal <- reject_proposals at 0;
		do end_conversation with: [message :: reject_proposal, contents :: []];
		happiness <- happiness - 5;
	}
	
	reflex answerOffer when: !empty(proposes) {
		message proposal <- proposes at 0;
		if target != nil and proposal.contents[0] = favoriteGenre {
			Bar proposedBar <- proposal.contents[1];
			do accept_proposal(message : proposal, contents : [proposedBar] );
			target <- proposedBar;
		} else {
			do reject_proposal(message : proposal, contents: [] );
		}
	}
	
	reflex enjoyBar when: !(empty(Bar at_distance 1)) {
		happiness <- happiness + 20;
		fullness <- fullness + 2;
	}
	
	reflex read_inform_message when: !(empty(informs)) {		
		loop i over: informs {
			do end_conversation with: [message :: i, contents :: []];
			if i.contents[1] = favoriteGenre and target = nil {
				target <- i.contents[0];
			}
		}
	}
	
	aspect base {
		draw circle(1) color: rgb(0,0,255,int(happiness * 2.55)) border: #black;
	}
}

species Stage skills: [fipa] {
	
	int soundDistance <- rnd(10,20);
	string genre <- genres[rnd(0, length(genres) - 1)];
	
	reflex newConcert when: flip(0.005) {
		genre <- genres[rnd(0, length(genres) - 1)];
		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [ self, genre ] ];
	}
	
	aspect base {
		draw square(5) color: #purple;
		draw circle(soundDistance) color:rgb(#purple,0.5);	
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