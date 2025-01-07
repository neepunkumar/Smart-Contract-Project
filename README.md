# Blockchain-based Carpooling System

This repository contains a blockchain-based carpooling system implemented in Solidity. The system leverages smart contracts to manage rides, passengers, and drivers while ensuring transparency, security, and efficiency through blockchain technology.

## Features

- **Driver and Passenger Registration**: Users must register as either a driver or passenger to use the platform.
- **Ride Management**: Drivers can create, start, and complete rides. Passengers can join available rides.
- **Payment Handling**: Passengers pay in Ether to book seats. Payment is transferred to the driver upon ride completion.
- **Ride Coordination**: Passengers can opt for coordinated ride assignment to minimize travel time deviation.
- **Smart Contracts**: Fully decentralized ride-sharing system using Ethereum smart contracts.

---

## File Structure

- **`contracts/`**
  - `car_pooling.sol`: Contains the core smart contract logic.
  - `Contracts.sol`: Defines reusable components like the `Location` enum.
- **`test/`**
  - `basic_contract_test.js`: Unit tests for basic functionalities.
  - `coordination_test.js`: Unit tests for the ride coordination mechanism.

---

## Smart Contract Overview

### Basic Functionalities

1. **Driver Registration**: Allows users to register as drivers.
2. **Passenger Registration**: Allows users to register as passengers.
3. **Ride Creation**: Drivers can create rides with the following parameters:
   - Travel time
   - Available seats
   - Seat price
   - Starting point
   - Destination
4. **Ride Booking**: Passengers can book rides by paying in Ether.
5. **Ride Status Management**: Drivers can start and complete rides. Payments are transferred upon completion.

### Coordination Mechanism

The coordination mechanism minimizes total travel time deviation for passengers who opt for coordinated ride assignment.

- **`awaitAssignRide`**: Passengers submit a request with their preferred travel time, source, destination, and deposit amount.
- **`assignPassengersToRides`**: Assigns passengers to available rides based on their preferences, refunding any excess deposit.

---

## How to Run

### Prerequisites

1. **Install Node.js and npm**:
   ```bash
   sudo apt install nodejs npm

Clone the Repository:


git clone https://github.com/your-repo/blockchain-carpooling.git
cd blockchain-carpooling

Install Dependencies:
npm install
Run Tests:


npx hardhat test
Deploy Contracts: Update the hardhat.config.js file with your network details and run:


npx hardhat run scripts/deploy.js --network <network-name>






