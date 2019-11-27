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
	list<Stage> stages;
	list<Guest> guests;
	list<BandMember> bandMembers;
	int loudestSoundDistance <- 20;
	int numberStages <- 3;
	int bandNumberN <- 0;
	
	init {
		create Stage number:numberStages returns: _stages;
		create Guest number:30 returns: _guests;
		create Bar number:3 returns: _bars;
		create FoodTruck number:5 returns: _foodTrucks;
		
		bandMembers <- createNewBandMembers(_stages);
		stages <- _stages;
		guests <- _guests;
		foodTrucks <- _foodTrucks;
		bars <- _bars;
	}
	
	list<BandMember> createNewBandMembers(list<Stage> emptyStages) {
		list<BandMember> newBandMembers;
		loop stage over:emptyStages{
			string genre <- genres[rnd(0, length(genres) - 1)];
			stage.genre <- genre;
			int timeToPlay <- rnd(20,100);
			create BandMember number:3 returns: _bandMembers;
			loop bandMember over: _bandMembers {
				bandMember.location <- {0,0,0};
				bandMember.BandNumber <- bandNumberN;
				bandMember.stage <- stage;
				bandMember.target <- stage.location;
				bandMember.genre <- genre;
				bandMember.timeToPlay <- timeToPlay;
			}
			newBandMembers <- newBandMembers + _bandMembers;
			bandNumberN <- bandNumberN + 1;
		}
		return newBandMembers;
	}
	
	reflex startNewConcert {
		list<Stage> emptyStages <- (Stage where (!each.concertRunning));
		write "emptyStages: " + emptyStages;
		bandMembers <- bandMembers + createNewBandMembers(emptyStages);
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
	
//	reflex printing {
//		write 
//			"name" + name + 
//			", happiness: " + happiness +
//			", target: " + target +
//			", fullness: " + fullness +
//			", favoriteGenre: " + favoriteGenre
//			;
//	}
	
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
			fullness <- 100;
			target <- nil;
		} else {
			target <- foodTrucks[rnd(0, length(foodTrucks) - 1)];
		}
	}
	
	reflex dancing when: target = nil and !(empty(Stage at_distance loudestSoundDistance)) {
		list<Stage> stagesGuestCanHear <- (Stage where (each.soundDistance > int(each.location distance_to location)));
		loop stage over: stagesGuestCanHear {
			if stage.genre = favoriteGenre {
				// write "At favourite stage";
				happiness <- happiness + 20;
				do wander;
				return;
			}
		}
		// write "Near stage, but not dancing. Target: " + target;
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
	
	int soundDistance <- rnd(10, loudestSoundDistance);
	string genre;
	bool concertRunning <- false;
	
//	reflex concertIsOver when: flip(0.05) {
//		genre <- genres[rnd(0, length(genres) - 1)];
//		do start_conversation with: [ to :: bandMembers, protocol :: 'fipa-query', performative :: 'inform', contents :: [ self, genre ] ];
//	}
	
	reflex newConcert when: !concertRunning {
		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [ self, genre ] ];
		concertRunning <- true;
	}
	
	aspect base {
		draw square(5) color: #purple;
		draw circle(soundDistance) color:rgb(#purple,0.5);	
	}
}

species BandMember skills: [moving, fipa] {
	int BandNumber;
	string genre;
	int timeToPlay;
	point target;
	Stage stage;
	
	reflex print {
		// write "target: " + target + " timeToPlay: " + timeToPlay + " stage: " + stage;
	}
	
	reflex goingToTarget when: target != nil {
		do goto target: target;
		do wander;
	}
	
	reflex targetReached when: target != nil and (target distance_to location < 1) {
		if target = {1000, 1000, 1000} {
			do die;
			return;
		}
		target <- nil;
	}
	
	reflex chillingAtTarget when: target = nil {
		do wander;
		timeToPlay <- timeToPlay - 1;
	}
	
	reflex finishedPlaying when: target = nil and timeToPlay < 0 {
		write name + " Finished playing!";
		ask stage {
			self.concertRunning <- false;
		}
		target <- {1000, 1000, 1000};
	}
	
	aspect base {
		draw circle(1) color:rgb(#black);	
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
			species BandMember aspect:base;
			species Bar aspect:base;
			species FoodTruck aspect:base;
			species Guest aspect:base;
		}
	}
}