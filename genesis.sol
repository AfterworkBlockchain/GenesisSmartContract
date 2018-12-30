pragma solidity >0.4.0;
pragma experimental ABIEncoderV2;

contract GenesisSpace{
    //specify a genesis country.
    struct Country {
        string name; 
        string description; 
        string programAddr; //address for mini programs
        string programURL; //URL for mini programs
        uint treasury;
        uint entryCost;
        uint exitCost;
        mapping (address => Citizen) citizens;
    }
    
    //specify a citizen.
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
    
    //Removes a citizen.
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
    
    //Gets citizen address list.
    function getCitizenList() public view returns (address[] memory) {
        return citizenList;
    }
    
    //Gets the address of the ith citizen from the citizen address list.
    function getCitizenList(uint i) public view returns (address) {
        return citizenList[i];
    }
    
    //Gets a citizen tuple based on the address.
    function getCitizen(address addr) public view returns (Citizen memory) {
        return country.citizens[addr];
    }
    
    //Gets balance for a citizen.
    function getCitizenBalance(address citizenAddr) public view returns (uint balance_) {
        balance_ = country.citizens[citizenAddr].balance;
    }
    
    //get the country name.
    function getName() public view returns (string memory) {
        return country.name;
    }
    
    //set the contry name (modifying name might involve voting).
    //function setName(string memory name_) public {
    //    country.name = name_;
    //}
    
    //get the country description.
    function getDescription() public view returns (string memory) {
        return country.description;
    }
    
    //set the contry description (modifying description might involve voting).
    //function setDescription(string memory description_) public {
    //    country.description = description_;
    //}
    
    //get the mini program address.
    function getProgramAddr() public view returns (string memory) {
        return country.programAddr;
    }
    
    //set the mini program address.
    function setName(string memory programAddr_) public {
        country.programAddr = programAddr_;
    }
    
    //get the mini program URL.
    function getProgramURL() public view returns (string memory) {
        return country.programURL;
    }
    
    //set the mini program URL.
    function setProgramURL(string memory programURL_) public {
        country.programURL = programURL_;
    }
    
    //get the entry cost.
    function getEntryCost() public view returns (uint) {
        return country.entryCost;
    }
    
    //set the entry cost.
    function setEntryCost(uint cost_) public {
        country.entryCost = cost_;
    }
    
    //get the exit cost.
    function getExitCost() public view returns (uint) {
        return country.exitCost;
    }
    
    //set the exit cost.
    function setExitCost(uint cost_) public {
        country.exitCost = cost_;
    }
}
