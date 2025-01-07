const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CarPoolingCoordination", function () {
  let CarPoolingCoordination;
  let carPoolingCoordination;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    CarPoolingCoordination = await ethers.getContractFactory("CarPoolingCoordination");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    carPoolingCoordination = await CarPoolingCoordination.deploy();
    await carPoolingCoordination.deployed();
  });

  describe("Passenger registration", function () {
    it("Should register a passenger", async function () {
      await carPoolingCoordination.connect(addr1).passengerRegister();
      const passenger = await carPoolingCoordination.getPassenger(addr1.address);
      expect(passenger.isRegistered).to.equal(true);
    });
  });

  describe("Driver registration", function () {
    it("Should register a driver", async function () {
      await carPoolingCoordination.connect(addr2).driverRegister();
      const driver = await carPoolingCoordination.getDriver(addr2.address);
      expect(driver.isRegistered).to.equal(true);
    });
  });

  describe("Ride creation", function () {
    it("Should create a ride", async function () {
      await carPoolingCoordination.connect(addr2).driverRegister();
      await carPoolingCoordination.connect(addr2).createRide(10, 2, ethers.utils.parseEther("1"), 0, 1);
      const ride = await carPoolingCoordination.getRideById(0);
      expect(ride.driver).to.equal(addr2.address);
    });
  });

  describe("Ride assignment", function () {
    it("Should assign a passenger to a ride", async function () {
      await carPoolingCoordination.connect(addr1).passengerRegister();
      await carPoolingCoordination.connect(addr2).driverRegister();
      await carPoolingCoordination.connect(addr2).createRide(10, 2, ethers.utils.parseEther("1"), 0, 1);
      await carPoolingCoordination.connect(addr1).awaitAssignRide(0, 1, 10, { value: ethers.utils.parseEther("1") });
      await carPoolingCoordination.assignPassengersToRides();
      const ride = await carPoolingCoordination.getRideById(0);
      expect(ride.passengerAddr[0]).to.equal(addr1.address);
    });
  });
});
