/***
* Name: BaseTask
* Author: minda
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Creative

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
	int numGuests <- 200;
	int bandNumberN <- 0;
	int sunLightAmount;
	rgb backgroundColor;
	
	init {
		create Stage number:numberStages returns: _stages;
		create Guest number:numGuests returns: _guests;
		create Bar number:3 returns: _bars;
		create FoodTruck number:5 returns: _foodTrucks;
		
		bandMembers <- createNewBandMembers(_stages);
		stages <- _stages;
		guests <- _guests;
		foodTrucks <- _foodTrucks;
		bars <- _bars;
	}

    int totalHappiness <- 0 update: int(sum(Guest collect (each.happiness)) / numGuests);
    int totalFullness <- 0 update: int(sum(Guest collect (each.fullness)) / numGuests);


	list<BandMember> createNewBandMembers(list<Stage> emptyStages) {
		list<BandMember> newBandMembers;
		loop stage over:emptyStages{
			string genre <- genres[rnd(0, length(genres) - 1)];
			stage.genre <- genre;
			stage.bandNumberPlaying <- bandNumberN;
			int timeToPlay <- rnd(100,300);
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
	
	int sunLight(int q) {
		int dayTime <- time mod 24;
		int sunLightInt;
		if dayTime < 12 {
			sunLightInt <- dayTime;
		} else {
			sunLightInt <- 24 - dayTime;
		}
		return sunLightInt;
	}
	
	rgb sunLightRGB(int sunLightInteger) {
		return rgb(255,255,255,int(sunLightInteger * 10.5));
	}
	
	reflex calculateRGBBackground {
		sunLightAmount <- sunLight(2);
		backgroundColor <- sunLightRGB(sunLightAmount);
	}
	
	reflex startNewConcert {
		list<Stage> emptyStages <- (Stage where (!each.concertRunning));
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
		
		if fullness < 0 {
			fullness <- 0;
		} else if fullness > 100 {
			fullness <- 100;
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
		if 
			(target is Stage and !(empty([target] at_distance (0.5 * Stage(target).soundDistance))))
			or 
			target.location - location = {0,0,0}
			// or 
			// [target] at_distance 2
			{
				target <- nil;
			}	
	}
	
	reflex moveAround when: target = nil {
		do wander;
	}
	
	reflex gettingHungry {
		fullness <- fullness - 1;
	}
	
	reflex starving when: fullness < starvingLevel {
		happiness <- happiness - 5;
		if !(target is FoodTruck) {
			target <- foodTrucks[rnd(0, length(foodTrucks) - 1)];
		}
	}
	
	reflex reachedFoodTruck when: target != nil and target is FoodTruck and !(empty(FoodTruck at_distance 2)) {
		FoodTruck nearFoodTruck <- (FoodTruck at_distance 2)[0];
		if !(FoodTruck(target) != nearFoodTruck) {
			return;
		}
		if nearFoodTruck.isVegan = isVegan {
			happiness <- happiness + 6;
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
				happiness <- happiness + 4;
				do wander;
				return;
			}
		}
		// write "Near stage, but not dancing. Target: " + target;
	}
	
	reflex offersGoingToBar when: target = nil and empty(Stage at_distance 20) and !empty(Guest at_distance 5) and (flip(sunLightAmount/24)) {
		list<Guest> nearbyGuests <- Guest at_distance 5;
		Guest selectedGuest <- nearbyGuests[rnd(0, length(nearbyGuests) - 1)];
		Bar selectedBar <- bars[rnd(0, length(bars) - 1)];
		do start_conversation with: [ to :: [selectedGuest], protocol :: 'fipa-query', performative :: 'propose', contents :: [favoriteGenre, selectedBar] ];
	}
	
	reflex PersonAcceptedBarOffer when: !empty(accept_proposals) {
		message accept_proposal <- accept_proposals at 0;
		Bar proposedBar <- accept_proposal.contents[0];
		target <- proposedBar;
		happiness <- happiness + 6;
	}
	
	reflex PersonDeclinedBarOffer when: !empty(reject_proposals) {
		message reject_proposal <- reject_proposals at 0;
		do end_conversation with: [message :: reject_proposal, contents :: []];
		happiness <- happiness - 1;
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
	
	reflex enjoyBar when: target != nil and target is Bar and !(empty(Bar at_distance 2)) {
		Bar nearBar <- (Bar at_distance 2)[0];
		if !(Bar(target) != nearBar) {
			return;
		}
		do goto target: nearBar;
		do wander;
		
		happiness <- happiness + 4;
		fullness <- fullness + 1;
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
		draw circle(1) color: rgb(200,0,0,int(happiness * 2.55)) border: #white;
	}
}

species Stage skills: [fipa] {
	
	int soundDistance <- rnd(10, loudestSoundDistance);
	string genre;
	bool concertRunning <- false;
	int bandNumberPlaying;
	
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
		do goto target: stage.location;
		do wander;
		timeToPlay <- timeToPlay - 1;
	}
	
	reflex finishedPlaying when: target = nil and timeToPlay < 0 {
		write name + " Finished playing!";
		ask stage {
			if self.bandNumberPlaying = myself.BandNumber {
				self.concertRunning <- false;
			}
		}
		target <- {1000, 1000, 1000};
	}
	
	aspect base {
		draw circle(1) color:rgb(#black);	
	}
	
}

species Bar {
	
	aspect base {
		draw triangle(10) color: #yellow;
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
		
		display my_display background: backgroundColor {
			species Stage aspect:base;
			species BandMember aspect:base;
			species Bar aspect:base;
			species FoodTruck aspect:base;
			species Guest aspect:base;
		}
		
		display chart {
        	chart "Chart1" type: series style: spline {
     		   	data "Total happiness" value: totalHappiness color: #green;
        		data "Total fullness" value: totalFullness color: #red;
        	}
    	}
	}
}





