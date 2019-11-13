/***
* Name: DifferentAuctions
* Author: vincent
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model DifferentAuctions

/* Insert your model definition here */

global {
	list<string> auction_types <- ["dutch", "english"];// , "sealed_bid"];
	
	list<string> interests <- ["CDs", "T-Shirts", "Shoes"];
	list<Guest> guests;
	Bank bank;
	
	init {
		create Guest number:50 returns:_guests;
		create Auctioneer number:1;
		create Bank number:1 returns: _banks;
		
		guests <- _guests;
		bank <- _banks at 0;
	}
}

species Guest skills: [fipa, moving] {
	
	string interest <- interests[rnd(length(interests) - 1)];
	Auctioneer auctioneer <- nil;
	int budget <- rnd(1, 10000);
	point target; 
	
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
		write name + ": Joining the auction. Interest: " + interest + ". Budget: " + budget;
	}
	
	reflex propose when: !empty(cfps) {
		list<message> cfp_messages <- cfps where (int (each.contents[0]) <= budget and each.contents[1] = auctioneer);
		if length(cfp_messages) = 0 {
			return nil;
		}
		message cfp_message <- cfp_messages at 0;
		write name + ": Accepting the offer. Lowest price: " + cfp_message.contents[0] + ". Bid: " + budget;
		do propose with: [ message :: cfp_message, contents :: [budget] ];  // Sending budget in case of sealed-bid auction
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
		budget <- budget - int(accept_proposals[0].contents[0]);
	}
	
	reflex broke when: budget < 1000 {
		target <- bank.location;
	}
	
	reflex reached_bank when: (target != nil) and !empty(Bank at_distance 0) {
		budget <- budget + rnd(5000, 9000);
		target <- {rnd(100), rnd(100), 1};
	}
	
	reflex going_to_target when: target != nil {
		do goto target: target;
	}
	
	reflex reached_target when: target - location = {0,0,0} {
		target <- nil;
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
	string auction_type <- "english";// <- auction_types[rnd(length(auction_types) - 1)];
	
	reflex status when: in_auction = true {
		write "current_price: " + current_price;
		write "bottom_price: " + bottom_price;
	}
	
	reflex reduce_price when: auction_type = "dutch" and in_auction and empty(proposes) {
		current_price <- current_price - 500;
		if current_price < bottom_price {
			// write name + ": Ending auction because of too low price";
			do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [self] ]; // ending auction
			in_auction <- false;
		} else {
			// write name + ": Lowering the price to " + current_price;
			do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'cfp', contents :: [current_price, self] ];
		}
	}
	
	reflex get_out_of_auction when: auction_type = "english" and in_auction and empty(proposes) {
		in_auction <- false;
	}
	
	reflex analyse_english_bids when: auction_type = "english" and in_auction and !empty(proposes) {
		
		write "In analyse_english_bids " + " current_price: " + current_price;
		
		if length(proposes) = 1 {
			in_auction <- false;
			message winner_proposal <- proposes at 0;
			do accept_proposal with: [ message :: winner_proposal, contents :: [current_price] ];
			do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [self] ]; // ending auction
			return;
		}
		
		int largestBidCount <- 0;
		list<message> english_proposes;
		message largestBid;
		loop propose over: proposes {
			// english_proposes[0] <- propose;
			if largestBidCount < int(propose.contents[0]) {
				largestBidCount <- int(propose.contents[0]);
				// largestBid <- propose;
				// do reject_proposal with: [ message :: propose, contents :: [] ];
			}
		}
		current_price <- largestBidCount;
		write name + "In analyse_english_bids; New highest bid: " + current_price;
		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'cfp', contents :: [largestBidCount, self] ];
		
		// loop propose over: english_proposes {}
		
	}
	
	reflex start_auction when: flip(0.05) and !in_auction {
		in_auction <- true;
		bottom_price <- rnd(1, 1000);
		write name + ": Starting auction of " + item + ". Auction_type: " + auction_type + ". Bottom price: " + bottom_price;
		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [item, self] ];
		if auction_type = "dutch" {
			current_price <- rnd(12000, 20000);
			do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'cfp', contents :: [current_price, self] ];
		} else if auction_type = "english" {
			current_price <- bottom_price;
			do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'cfp', contents :: [bottom_price, self] ];
		}
	}
	
	
	reflex end_auction when: auction_type = "dutch" and in_auction and !empty(proposes) {
		message winner_proposal <- proposes at 0;
		
		// write name + ": Ending auction. Sold at: " + current_price;
		
		do accept_proposal with: [ message :: winner_proposal, contents :: [current_price] ];
		loop propose over: proposes {
			do reject_proposal with: [ message :: propose, contents :: [] ];
		}
		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [self] ]; // ending auction
		in_auction <- false;
	}
	
	aspect base {
		rgb AuctColor;
		if !in_auction {
			AuctColor <- #black;
		} else if item = "CDs" {
			AuctColor <- #red;
		} else if item = "Shoes" {
			AuctColor <- #green;
		} else if item = "T-Shirts" {
			AuctColor <- #blue;
		}
		
		if auction_type = "english" {
			draw circle(2) color: AuctColor;
		} else if auction_type = "dutch" {
			draw square(5) color: AuctColor;
		} else if auction_type = "sealed_bid" {
			draw triangle(5) color: AuctColor;
		}
	}
}

species Bank skills: [] {
	aspect base {
		draw triangle(10) color: #green;
	}
}



experiment my_experiment type:gui {
	output {
		display my_display {
			species Guest aspect:base;
			species Auctioneer aspect:base;
			species Bank aspect:base;
		}
	}
}