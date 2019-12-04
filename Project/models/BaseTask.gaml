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
	int numGuests <- 200;
	int bandNumberN <- 0;
	
	init {
		create Stage number:numberStages returns: _stages;
		create Guest number:numGuests returns: _guests;
		create Bar number:2 returns: _bars;
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
			int timeToPlay <- rnd(30,100);
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
		bandMembers <- bandMembers + createNewBandMembers(emptyStages);
	}
}


species Guest skills: [fipa, moving] {
	
	int happiness <- 50;
	FestivalLocation target <- nil;
	bool atTarget <- true;
	bool isVegan <- flip(0.3);
	float fullness <- float(rnd(1, 100));
	int extravertLevel <- rnd(1, 100);
	int starvingLevel <- 20;
	string favoriteGenre <- genres[rnd(0, length(genres) - 1)];
	
	reflex equalifyValues {
		if happiness < 0 {
			happiness <- 0;
		} else if happiness > 100 {
			happiness <- 100;
		}
		
//		if fullness < 0 {
//			fullness <- 0;
//		} else if fullness > 100 {
//			fullness <- 100;
//		}
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
	
	reflex goingToTarget when: !atTarget or (target != nil and target.location distance_to location > target.radius) {
		do goto target: target;
	}
	
	reflex wanderAroundTarget when: atTarget {
		do wander;
		
		if (target is FoodTruck) {
			if (isVegan != FoodTruck(target).isVegan) {
				target <- nil;
				return;	
			}
			fullness <- 100.0;
			happiness <- happiness + 1;
		} else if (target is Stage) {
			list<Guest> peopleAround <- Guest at_distance 5;
			happiness <- happiness + int(length(peopleAround) / 10);
		} else if (target is Bar) {
			list<Guest> peopleAround <- Guest at_distance 5;
			if (length(peopleAround) > 0) {
				float avgExtravertLevel <- sum(peopleAround collect (each.extravertLevel - 50)) / length(peopleAround);
				int barHappiness <- int((extravertLevel - 50) * avgExtravertLevel / 100);
				happiness <- happiness + barHappiness; 
			}	
		}
	}
	
	reflex targetReached when: !atTarget and target.location distance_to location < target.radius {
		atTarget <- true;
	}
	
	reflex gettingHungry {
		if (fullness > 0) {
			fullness <- fullness - 0.1;
		}
	}
	
	reflex starving when: fullness < starvingLevel {
		happiness <- happiness - 1;
		if !(target is FoodTruck) {
			atTarget <- false;
			target <- foodTrucks[rnd(0, length(foodTrucks) - 1)];
		}
	}	
	
	reflex offersGoingToBar when: atTarget and !empty(Guest at_distance 5) and flip((extravertLevel + happiness) / 200 * 0.01) {
		Guest selectedGuest <- Guest at_distance 5 at 0;
		Bar selectedBar <- bars[rnd(0, length(bars) - 1)];
		do start_conversation with: [ to :: [selectedGuest], protocol :: 'fipa-query', performative :: 'propose', contents :: [favoriteGenre, selectedBar] ];
	}
	
	reflex guestAcceptedBarOffer when: !empty(accept_proposals) {
		message accept_proposal <- accept_proposals at 0;
		Bar proposedBar <- accept_proposal.contents[0];
		do end_conversation with: [message :: accept_proposal, contents :: []];
		target <- proposedBar;
		atTarget <- false;
		happiness <- happiness + 1;
	}
	
	reflex guestDeclinedBarOffer when: !empty(reject_proposals) {
		message reject_proposal <- reject_proposals at 0;
		do end_conversation with: [message :: reject_proposal, contents :: []];
		happiness <- happiness - 1;
	}
	
	reflex answerOffer when: !empty(proposes) {
		message proposal <- proposes at 0;
		if atTarget and proposal.contents[0] = favoriteGenre {
			Bar proposedBar <- proposal.contents[1];
			do accept_proposal(message : proposal, contents : [proposedBar] );
			target <- proposedBar;
			atTarget <- false;
		} else {
			do reject_proposal(message : proposal, contents: [] );
		}
	}
	
	reflex read_inform_message when: !(empty(informs)) {		
		loop i over: informs {
			do end_conversation with: [message :: i, contents :: []];
			if i.contents[1] = favoriteGenre and atTarget {
				target <- i.contents[0];
				atTarget <- false;
			}
		}
	}
	
	aspect base {
//		draw circle(1) color: #black;
//		draw circle(extravertLevel / 100.0) color: #white;
//		draw circle(extravertLevel / 100.0) color: rgb(0,0,255,int(happiness * 2.55));
		draw circle(1) color: rgb(0,0,255,int(happiness * 2.55)) border: #black;
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

species FestivalLocation {
	
	int radius;
	
}

species Bar parent: FestivalLocation {
	
	init {
		radius <- 5;
	}
	
	aspect base {
		draw triangle(5) color: #yellow;
		draw circle(radius) color:rgb(#purple,0.5);
	}
}

species FoodTruck parent: FestivalLocation {
	
	init {
		radius <- 5;
	}
	
	bool isVegan <- flip(0.5);
	
	aspect base {
		draw triangle(5) color: isVegan ? #green : #red;
		draw circle(radius) color:rgb(#purple,0.5);
	}
}


species Stage parent: FestivalLocation skills: [fipa] {
	
	init {
		radius <- rnd(10,20);
	}
	
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
		draw circle(radius) color:rgb(#purple,0.5);	
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
		
		display chart {
        	chart "Chart1" type: series style: spline {
     		   	data "Total happiness" value: totalHappiness color: #green;
        		data "Total fullness" value: totalFullness color: #red;
        	}
    	}
	}
}