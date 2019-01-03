pragma solidity >0.4.0;
//pragma experimental ABIEncoderV2;

contract GenesisSpace{
    //define a genesis country.
    struct Country {
        string name; 
        string description; 
        string programAddr; //address for mini programs
        string programURL; //URL for mini programs
        uint treasury;
        uint entryCost;
        uint exitCost;
        //mapping (address => Citizen) citizens;//TODO: not sure if we need this.
    }
    
    //define a citizen. TODO: not sure if we need this. For now, we simplify it.
    //struct Citizen {
    //    string name;
    //    uint balance; 
    //}
    
    Country country;
    address payable countryCreator;
    address[] citizenList;
    mapping (address => uint) balances;
    
    //create a country.
    constructor(string memory name_, string memory description_) public {
        countryCreator = msg.sender;
        country.name = name_;
        country.description = description_;
    }
    
    modifier onlyCountry() {
        require(
            msg.sender == countryCreator,
            "Only country can call this."
        );
        _;
    }
    
    modifier onlyCitizen() {
        require(
            msg.sender != countryCreator,
            "Only citizen can call this."
        );
        _;
    }
    
    //join the country. It can be only called by citizens.
    function join() public onlyCitizen payable returns (bool) {
        require(msg.value >= country.entryCost+country.exitCost, "The money sent must be larger than the sum of the entry and exit cost!");
        countryCreator.transfer(country.entryCost); // the money is transferred to the address of the country creator.
        country.treasury += country.entryCost; //update the treasury
        balances[msg.sender] = msg.value - country.entryCost;
        //Citizen memory citizen = Citizen(name_, msg.sender.balance);
        //country.citizens[msg.sender] = citizen; //TODO:check whether the citizen already exists
        citizenList.push(msg.sender); //add the citizen address to the citizen list
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
    
    //leave the country. 
    function leave() public onlyCitizen payable returns (bool) {
        balances[msg.sender] += msg.value; 
        require(balances[msg.sender] >= country.exitCost, "Fail to pay the exit cost!");
        countryCreator.transfer(country.exitCost);
        balances[msg.sender] -= country.exitCost;
        country.treasury += country.exitCost;
        uint index = lookup(msg.sender);
        if(index < citizenList.length) {
            citizenList[index] = citizenList[citizenList.length-1]; 
            citizenList.length--;
            //delete country.citizens[msg.sender];
            return true;
        } else {
            return false;
        }
    }
    
    //get citizen address list.
    function getCitizenList() public view returns (address[] memory) {
        return citizenList;
    }
    
    //get the address of the ith citizen from the citizen address list.
    function getCitizenList(uint i) public view returns (address) {
        return citizenList[i];
    }
    
    //get the citizen name based on the citizen address.
    //function getCitizenName(address citizenAddr) public view returns (string memory) {
    //    return country.citizens[citizenAddr].name;
    //}
    
    //get balance for a citizen.
    //function getCitizenBalance(address citizenAddr) public view returns (uint balance_) {
    //    balance_ = country.citizens[citizenAddr].balance;
    //}
    
    //get balance based on a citizen address.
    function getBalance(address addr) public view returns (uint) {
        return balances[addr];
    }
    
    //get the country name.
    function getName() public view returns (string memory) {
        return country.name;
    }
    
    //set the contry name. TODO: modifying name might involve voting.
    function setName(string memory name_) public onlyCountry {
        country.name = name_;
    }
    
    //get the country description.
    function getDescription() public view returns (string memory) {
        return country.description;
    }
    
    //set the contry description. TODO: modifying name might involve voting.
    function setDescription(string memory description_) public onlyCountry {
        country.description = description_;
    }
    
    //get the mini program address.
    function getProgramAddr() public view returns (string memory) {
        return country.programAddr;
    }
    
    //set the mini program address.
    function setProgramAddr(string memory programAddr_) public {
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
    function setEntryCost(uint cost_) public onlyCountry {
        country.entryCost = cost_;
    }
    
    //get the exit cost.
    function getExitCost() public view returns (uint) {
        return country.exitCost;
    }
    
    //set the exit cost.
    function setExitCost(uint cost_) public onlyCountry {
        country.exitCost = cost_;
    }
    
    //get the country treasury.
    function getTreasury() public onlyCountry view returns (uint) {
        return country.treasury;
    }
}
