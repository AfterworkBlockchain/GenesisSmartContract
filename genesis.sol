pragma solidity >0.4.0;
pragma experimental ABIEncoderV2;

contract GenesisSpace{
    //define a genesis country.
    struct Country {
        string name;
        string description;
        uint treasury;
        mapping (address => Citizen) citizens;
    }
    
    //define a citizen.
    struct Citizen {
        string name;
        uint balance;
    }
    
    Country country;
    address[] citizenList;
    
    //create a country with name, description and treasury.
    constructor(string memory name_, string memory description_, uint treasury_) public {
        country.name = name_;
        country.description = description_;
        country.treasury = treasury_;
    }
    
    //The country accepts a citizen.
    function accept(address citizenAddr, Citizen memory citizen) public returns (bool) {
        //TODO: apply the entrance rules. For now, we accept all citizens.
        country.citizens[citizenAddr] = citizen; //link the address to the citizen
        citizenList.push(citizenAddr); //add the citizen address to the citizen list
        return true;
    }
    
    //look up the index of a citizen in the citizen list.
    function lookup(address citizenAddr) private view returns (uint) {
        uint i = 0;
        for(; i < citizenList.length; i++) {
            if(citizenList[i] == citizenAddr) return i;
        }
        require(i != citizenList.length, "Citizen is not found!");
    }
    
    //Remove a citizen.
    function remove(address citizenAddr) public returns (bool) {
        uint index = lookup(citizenAddr);
        if(index < citizenList.length) {
            citizenList[index] = citizenList[citizenList.length-1]; 
            citizenList.length--;
            delete country.citizens[citizenAddr];
            return true;
        } else {
            return false;
        }
    }
    
    //Get citizen address list.
    function getCitizenList() public view returns (address[] memory) {
        return citizenList;
    }
    
    //Get the address of the ith citizen from the citizen address list.
    function getCitizenList(uint i) public view returns (address) {
        return citizenList[i];
    }
    
    //Get a citizen tuple based on the address.
    function getCitizen(address addr) public view returns (Citizen memory) {
        return country.citizens[addr];
    }
    
    //Get balance for a citizen.
    function getCitizenBalance(address citizenAddr) public view returns (uint balance_) {
        balance_ = country.citizens[citizenAddr].balance;
    }
    
}
