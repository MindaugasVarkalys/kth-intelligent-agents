/***
* Name: NewTryModel
* Author: vincent
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model NewTryModel

/* Insert your model definition here */


/* Insert your model definition here */

global {
	
	list<string> auction_statuses <- ["initialised", "guests_listening", "bidding"];
	
	list<string> statuses <- ["waiting", "in_auction"];
	
	
	list<string> interests <- ["CD", "T-Shirt", "Shoes"];
	list<Guest> guests;
	
	init {
		create Guest number:5 returns:_guests;
		create Auctioneer number:1;
		
		guests <- _guests;
	}
}

species Guest skills: [fipa] {
	
//	string interest <- interests[rnd(length(interests) - 1)];
//	Auctioneer auctioneer <- nil;
//	int budget <- rnd(1, 10000);
//	
//	reflex join_auction when: (!empty(informs) and auctioneer = nil) {
//		list<message> auction_messages <- (informs where (each.contents[0] = interest));
//		if length(auction_messages) = 0 {
//			return nil;
//		}
//		message auction_message <- auction_messages at 0;
//		auctioneer <- auction_message.contents[1];
//		write name + ": Joining the auction. Interest: " + interest + ". Budget: " + budget + "auction_message: " + auction_message;
//	}
//	
//	reflex propose when: !empty(cfps) {
//		list<message> cfp_messages <- cfps where (int (each.contents[0]) <= budget and each.contents[1] = auctioneer);
//		if length(cfp_messages) = 0 {
//			return nil;
//		}
//		message cfp_message <- cfp_messages at 0;
//		write name + ": Accepting the offer";
//		do propose with: [ message :: cfp_message, contents :: [] ];
//	}
//	
//	reflex exit_auction when: !empty(informs where (each.contents[0] = auctioneer)) {
//		write name + ": Exiting the auction because it's closed";
//		auctioneer <- nil;
//	}
//	
//	reflex lost_auction when: !empty(reject_proposals) {
//		write name + ": Lost the auction";
//		auctioneer <- nil;
//	}
//	
//	reflex won_auction when: !empty(accept_proposals) {
//		write name + ": Won the auction";
//		auctioneer <- nil;
//	}
	
	aspect base {
		draw circle(1) color: auctioneer = nil ? #black : #red;
	}
}


species Auctioneer skills: [fipa] {
	
//	string item <- interests[rnd(length(interests) - 1)];
//	int current_price;
//	int bottom_price;
//	bool in_auction <- false;
//	bool first_proposal <- false;
//	
//	reflex start_auction when: time mod rnd(1000) = 0 and !in_auction {
//		in_auction <- true;
//		first_proposal <- true;
//		current_price <- rnd(1000, 10000);
//		bottom_price <- rnd(1, 1000);
//		
//		write name + ": Starting auction of " + item + ". Current price: " + current_price + ". Bottom price: " + bottom_price;
//		
//		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [item, self] ];
//	}
//	
//	reflex first_proposal when: in_auction and first_proposal {
//		do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'cfp', contents :: [current_price, self] ];
//		first_proposal <- false;
//	} 
//	
//	reflex end_auction when: in_auction and !empty(proposes) and !first_proposal {
//		message winner_proposal <- proposes at 0;
//		
//		write name + ": Ending auction. Sold at: " + current_price;
//		
//		do accept_proposal with: [ message :: winner_proposal, contents :: [] ];
//		loop i from: 1 to: length(proposes) - 1 step: 1 {
//			do reject_proposal with: [ message :: proposes[i], contents :: [] ];
//		}		
//		in_auction <- false;
//	}
//	
//	reflex reduce_price when: in_auction and empty(proposes) and !first_proposal {
//		current_price <- current_price - 5;
//		if current_price < bottom_price {
//			write name + ": Ending auction because of too low price";
//			do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'inform', contents :: [self] ];
//			in_auction <- false;
//		} else {
//			write name + ": Lowering the price to " + current_price;
//			do start_conversation with: [ to :: guests, protocol :: 'fipa-query', performative :: 'cfp', contents :: [current_price, self] ];
//		}
//	}
		
	aspect base {
		draw square(2) color: in_auction ? #red : #black;
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