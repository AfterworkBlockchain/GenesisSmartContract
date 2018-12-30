pragma solidity >=0.4.0 <0.6.0;
pragma experimental ABIEncoderV2;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "./genesis.sol";

contract genesisTest {
    GenesisSpace countrytotest;
    
    function beforeAll() public {
        countrytotest = new GenesisSpace("genesis", "This is a genesis space country", 1000);
    }
    
    //Test the accept function - accepting citizens
    function checkAcceptingCitizen() public {
        countrytotest.accept(address(1), GenesisSpace.Citizen("Anna", 10));
        countrytotest.accept(address(2), GenesisSpace.Citizen("Bob", 20));
        //test the citizen list
        Assert.equal(countrytotest.getCitizenList().length, 2, "Length does not match!");
        Assert.equal(countrytotest.getCitizenList(0), address(1), "Address does not match!");
        //test the mapping of citizens
        Assert.equal(countrytotest.getCitizen(address(1)).name, "Anna", "Anna should be the citizen name!");
        Assert.equal(countrytotest.getCitizen(address(1)).balance, 10, "Anna: Balance does not match!");
        Assert.equal(countrytotest.getCitizen(address(2)).name, "Bob", "Bob should be the citizen name!");
        Assert.equal(countrytotest.getCitizen(address(2)).balance, 20, "Bob: Balance does not match!");
    }
    
    //Test the remove function - removing citizens
    function checkRemovingCitizen() public {
        //remove the first citizen
        Assert.ok(countrytotest.remove(address(1)), "Cannot remove the citizen!");
        Assert.equal(countrytotest.getCitizenList().length, 1, "Length does not match!");
        
        //remove the second citizen
        Assert.ok(countrytotest.remove(address(2)), "Cannot remove the citizen!");
        Assert.equal(countrytotest.getCitizenList().length, 0, "Length does not match!");
    }
}
