
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CarPooling {
    
    enum RideStatus {BookingOpen, FullyBooked, Started, Completed}
    enum Location {A, B, C}

    struct Ride {
        uint256 rideId;
        address driver;
        uint8 travelTime;
        uint8 availableSeats;
        uint8 totalSeats;
        uint256 seatPrice;
        Location origin;
        Location destination;
        RideStatus status; // status of the ride
        address[] passengerAddr; // addresses of all passengers who booked the ride
    }

    struct Driver {
        bool isRegistered;
        bool hasRide;
    }

    struct Passenger {
        bool isRegistered;
        bool hasRide;
    }

    mapping(uint256 => Ride) internal rides;
    mapping(address => Driver) internal drivers;
    mapping(address => Passenger) internal passengers;
    uint256 internal rideCounter;
    uint256 public numRides;
    // Your auxiliary data structures here, if required

    event RideCreated(uint256 rideId, address driver, uint8 travelTime, uint8 availableSeats, uint256 seatPrice, Location origin, Location destination);
    event RideJoined(uint256 rideId, address passenger);
    event RideStarted(uint256 rideId);
    event RideCompleted(uint256 rideId);

    constructor() {}

    modifier onlyDriver(){
        require(drivers[msg.sender].isRegistered, "Caller is not a registered driver");
        _;
    }

    modifier onlyPassenger(){
        require(passengers[msg.sender].isRegistered, "Caller is not a registered passenger");
        _;
    }

    modifier notDriver(){
        require(!drivers[msg.sender].isRegistered, "Caller is already a registered driver");
        _;
    }

    modifier notPassenger(){
        require(!passengers[msg.sender].isRegistered, "Caller is already a registered passenger");
        _;
    }

    modifier driverSingleRide(){
        require(!drivers[msg.sender].hasRide, "Driver can only create one ride at a time");
        _;
    }

    modifier passengerSingleRide(){
        require(!passengers[msg.sender].hasRide, "Passenger can only join one ride at a time");
        _;
    }

    function passengerRegister() public notPassenger{
        passengers[msg.sender].isRegistered = true;
    }

    function driverRegister() public notDriver{
        drivers[msg.sender].isRegistered = true;
    }

    function createRide(uint8 _travelTime, uint8 _availableSeats, uint256 _seatPrice, Location _origin, Location _destination) public onlyDriver driverSingleRide{
        require(_travelTime >= 0 && _travelTime <= 23, "Invalid travel time");
        require(_origin != _destination, "Origin and destination must be different");
        require(_seatPrice > 0, "Seat price must be greater than zero");
        require(_availableSeats > 0, "Available seats must be greater than zero");
        
        uint256 rideId = rideCounter;
        rides[rideId] = Ride(rideId, msg.sender, _travelTime, _availableSeats, _availableSeats, _seatPrice, _origin, _destination, RideStatus.BookingOpen, new address[](0));
        drivers[msg.sender].hasRide = true;
        rideCounter++;
        numRides++;
        
        emit RideCreated(rideId, msg.sender, _travelTime, _availableSeats, _seatPrice, _origin, _destination);
    }

    function findRides(Location _source, Location _destination) public view returns (uint256[] memory) {
        uint256[] memory matchingRides = new uint256[](rideCounter);
        uint256 count = 0;
        
        for (uint256 i = 0; i < rideCounter; i++) {
            if (rides[i].origin == _source && rides[i].destination == _destination && rides[i].status == RideStatus.BookingOpen) {
                matchingRides[count] = i;
                count++;
            }
        }
        
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = matchingRides[i];
        }
        
        return result;
    }

    function joinRide(uint256 _rideId) public payable onlyPassenger passengerSingleRide{
        Ride storage ride = rides[_rideId];
        require(ride.status == RideStatus.BookingOpen, "Ride is not open for booking");
        require(msg.value == ride.seatPrice, "Payment amount does not match the seat price");
        require(ride.availableSeats > 0, "No available seats");
        
        passengers[msg.sender].hasRide = true;
        ride.passengerAddr.push(msg.sender);
        ride.availableSeats--;
        
        if (ride.availableSeats == 0) {
            ride.status = RideStatus.FullyBooked;
        }
        
        emit RideJoined(_rideId, msg.sender);
    }

    function startRide(uint256 _rideId) public onlyDriver{
        Ride storage ride = rides[_rideId];
        require(msg.sender == ride.driver, "Only the driver can start the ride");
        require(ride.status == RideStatus.FullyBooked || ride.status == RideStatus.BookingOpen, "Ride is not in the correct state");
        
        ride.status = RideStatus.Started;
        emit RideStarted(_rideId);
    }

    function completeRide(uint256 _rideId) public onlyDriver{
        Ride storage ride = rides[_rideId];
        require(msg.sender == ride.driver, "Only the driver can complete the ride");
        require(ride.status == RideStatus.Started, "Ride is not in the started state");
        
        ride.status = RideStatus.Completed;
        drivers[msg.sender].hasRide = false;
        
        uint256 totalPayment = ride.passengerAddr.length * ride.seatPrice;
        payable(msg.sender).transfer(totalPayment);
        
        for (uint256 i = 0; i < ride.passengerAddr.length; i++) {
            passengers[ride.passengerAddr[i]].hasRide = false;
        }
        
        emit RideCompleted(_rideId);
    }

    // -------------------- Already implemented functions, do not modify ------------------
    function getDriver(address addr) public view returns (Driver memory){
        return(drivers[addr]);
    }

    function getPassenger(address addr) public view returns (Passenger memory){
        return(passengers[addr]);
    }

    function getRideById(uint256 _rideId) public view returns (Ride memory){
        return(rides[_rideId]);
    }
}


contract CarPoolingCoordination is CarPooling {
    event Refund_Failed(address passenger, uint256 amount);
    struct Passenger_Request {
        address passenger;
        Location source;
        Location destination;
        uint8 preferredTravelTime;
        uint256 depositAmount;
        bool isAssigned;
    }

    Passenger_Request[] public coordinationRequests;
    mapping(address => uint256) private passengerToRequestId;


    function awaitAssignRide(Location _source, Location _destination, uint8 _preferredTravelTime) public payable onlyPassenger {
        require(_source != _destination, "Origin and destination must be different");
        require(_preferredTravelTime < 24, "Preferred travel time must be between 0 and 23");
        require(msg.value > 0, "Deposit must be greater than zero");
        require(passengerToRequestId[msg.sender] == 0, "Passenger already has a pending request");

        Passenger_Request memory newRequest = Passenger_Request({
            passenger: msg.sender,
            source: _source,
            destination: _destination,
            preferredTravelTime: _preferredTravelTime,
            depositAmount: msg.value,
            isAssigned: false
        });
        coordinationRequests.push(newRequest);
        passengerToRequestId[msg.sender] = coordinationRequests.length - 1;
    }

    
    //This function is a part of a larger ride-sharing contract and is responsible for 
    //assigning passengers to rides and handling the associated logistics like updating 
    //the ride status and refunding any excess deposit amount.
    function handle_Passengers(uint256 rideId, Passenger_Request storage request) private {
        Ride storage ride = rides[rideId];
        ride.passengerAddr.push(request.passenger);
        ride.availableSeats--;
        if (ride.availableSeats == 0) {
            ride.status = RideStatus.FullyBooked;
        }

        uint256 refund_Amount = request.depositAmount - ride.seatPrice;
        if (refund_Amount > 0) {
            refund_Passenger(request.passenger, refund_Amount);
        }

        request.isAssigned = true;
        passengers[request.passenger].hasRide = true;
    }
    // Refund the passenger in case of failed assignment
    function refund_Passenger(address passenger, uint256 amount) private {
        (bool success, ) = payable(passenger).call{value: amount}("");
        if (!success) {
            emit Refund_Failed(passenger, amount);
        }
    }
    // Sort the requests based on the preferred travel time
    function sort_Requests_By_PreferredTime() private {
        uint256 n = coordinationRequests.length;
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (coordinationRequests[j].preferredTravelTime > coordinationRequests[j + 1].preferredTravelTime) {
                    Passenger_Request memory temp = coordinationRequests[j];
                    coordinationRequests[j] = coordinationRequests[j + 1];
                    coordinationRequests[j + 1] = temp;
                }
            }
        }
    }

function assignPassengersToRides() public {
        sort_Requests_By_PreferredTime();
        uint256 numRequests = coordinationRequests.length;

        for (uint256 i = 0; i < numRequests; i++) {
            if (coordinationRequests[i].isAssigned) continue; // Skip already assigned requests

            Passenger_Request storage request = coordinationRequests[i];
            uint256[] memory availableRides = findRides(request.source, request.destination);
            uint256 bestRideId = type(uint256).max; // Initialize best ride ID to maximum possible value
            uint256 minCost = type(uint256).max; // Initialize minimum cost to maximum possible value

            // Find the ride with the minimum time deviation
            for (uint256 j = 0; j < availableRides.length; j++) {
                uint256 rideId = availableRides[j];
                Ride storage ride = rides[rideId];
                if (ride.availableSeats > 0 && ride.status == RideStatus.BookingOpen) { // Check if ride is available
                    uint256 cost = time_Deviation(request.preferredTravelTime, ride.travelTime);
                    if (cost < minCost) {
                        minCost = cost;
                        bestRideId = rideId;
                    }
                }
            }

            // If a suitable ride is found, assign the passenger to that ride
            if (bestRideId != type(uint256).max) {
                handle_Passengers(bestRideId, request);
            } else {
                // If no suitable ride is found, refund the passenger and remove the request
                refund_Passenger(request.passenger, request.depositAmount);
                passengerToRequestId[request.passenger] = 0; // Clear the mapping record
            }
        }

        delete coordinationRequests; // Clear the request queue, awaiting new requests
}



    // calculate the time deviation between the preferred time and the actual time
   function time_Deviation(uint256 preferredTime, uint256 actualTime) private pure returns (uint256) {
    unchecked {
        if (preferredTime > actualTime) {
            return preferredTime - actualTime;
        } else {
            return actualTime - preferredTime;
        }
    }
}
    }

