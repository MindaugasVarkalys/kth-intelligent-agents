/***
* Name: Assignment2
* Author: minda
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BaseTask


/* Insert your model definition here */

global {
	list<string> statuses <- ["waiting", "in_auction"];
	
	
	list<string> interests <- ["CDs", "T-Shirts", "Shoes"];
	list<Guest> guests;
	
	init {
		create Guest number:50 returns:_guests;
		create Auctioneer number:3;
		
		guests <- _guests;
	}
}

species Guest skills: [fipa, moving] {
	
	string interest <- interests[rnd(length(interests) - 1)];
	Auctioneer auctioneer <- nil;
	int budget <- rnd(1, 10000);
	
	reflex dance when: auctioneer = nil {
		do wander;
	}
	
	reflex join_auction when: (!empty(informs) and auctioneer = nil) {
		list<message> auction_messages <- (informs where (each.contents[0] = interest));
		if length(auction_messages) = 0 {
			return nil;
		}
		message auction_message <- auction_messages at 0;
		auctioneer <- auction_message.contents[1];
		write name + ": Joining the auction. Interest: " + interest + ". Budget: " + budget + ". auction_message: " + auction_message;
	}
	
	reflex propose when: !empty(cfps) {
		list<message> cfp_messages <- cfps where (int (each.contents[0]) <= budget and each.contents[1] = auctioneer);
		if length(cfp_messages) = 0 {
			return nil;
		}
		message cfp_message <- cfp_messages at 0;
		write name + ": Accepting the offer";
		do propose with: [ message :: cfp_message, contents :: [] ];
	}
	
	reflex exit_auction when: !empty(informs) {
		list<message> inform_messages_from_auctioneer <- (informs where (each.contents[0] = auctioneer));
		if length(inform_messages_from_auctioneer) = 0 {
			return nil;
		}		
		write name + ": Exiting the auction because it's closed";
		auctioneer <- nil;
	}
	
	reflex lost_auction when: !empty(reject_proposals) {
		write name + " lost the auction. time: " + time;
		auctioneer <- nil;
		do end_conversation with: [message :: reject_proposals[0], contents :: []];
	}
	
	reflex won_auction when: !empty(accept_proposals) {
		write name + " won the auction. time: " + time;
		auctioneer <- nil;
		do end_conversation with: [message :: accept_proposals[0], contents :: []];
	}
	
	aspect base {		
		if auctioneer = nil {
			draw circle(1) color: #black;
			return;
		}
		if auctioneer.item = "CDs" {
			draw circle(1) color: #red;
		} else if auctioneer.item = "Shoes" {
			draw circle(1) color: #green;
		} else if auctioneer.item = "T-Shirts" {
			draw circle(1) color: #blue;
		}
	}
}


species Auctioneer skills: [fipa] {
	
	string item <- interests[rnd(length(interests) - 1)];
	int current_price;
	int bottom_price;
	bool in_auction <- false;
	
	reflex reduce_price when: in_auction and empty(proposes) {
		write "time in reduce_price: " + time;
		current_price <- current_price - 500;
		if current_price < bottom_price {
			write name + ": Ending auction because of too low price";
			do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [self] ]; // ending auction
			in_auction <- false;
		} else {
			write name + ": Lowering the price to " + current_price;
			do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'cfp', contents :: [current_price, self] ];
		}
	}
	
	reflex start_auction when: flip(0.1) and !in_auction {
		in_auction <- true;
		current_price <- rnd(12000, 20000);
		bottom_price <- rnd(1, 1000);
		write "time in start_auction: " + time;
		
		write name + ": Starting auction of " + item + ". Current price: " + current_price + ". Bottom price: " + bottom_price;
		
		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [item, self] ];
		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'cfp', contents :: [current_price, self] ];
	}
	
	
	reflex end_auction when: in_auction and !empty(proposes) {
		message winner_proposal <- proposes at 0;
		
		write name + ": Ending auction. Sold at: " + current_price;
		
		do accept_proposal with: [ message :: winner_proposal, contents :: [] ];
		loop propose over: proposes {
			do reject_proposal with: [ message :: propose, contents :: [] ];
		}
		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [self] ]; // ending auction
		in_auction <- false;
	}
	
	aspect base {
		if !in_auction {
			draw square(5) color: #black;
			return;
		}
		if item = "CDs" {
			draw square(5) color: #red;
		} else if item = "Shoes" {
			draw square(5) color: #green;
		} else if item = "T-Shirts" {
			draw square(5) color: #blue;
		}
	}
}



experiment my_experiment type:gui {
	output {
		display my_display {
			species Guest aspect:base;
			species Auctioneer aspect:base;
		}
	}
}