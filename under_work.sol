pragma solidity >=0.5.0;
//pragma experimental ABIEncoderV2;

contract GenesisSpace{
    //define a citizen. 
    struct Citizen {
        uint256 balance; 
        uint8   status; // 0 left, 1 normal, 2 limited, 99 forbidden
        uint256 weight;
    }
    
    //define a genesis country.
    struct Country {
        string name; 
        string description; 
        address programAddr; //address for mini programs
        string programURL; //URL for mini programs
        uint256 treasury;
        uint256 entryCost;
        uint256 exitCost;
        mapping (address => Citizen) citizens;
    }
    
    address admin = 0x564F0D7C4456950dd5c0cc47E6fA330321951806;
    mapping(uint256 => bool) usedNonces;
    Country country;
    address payable countryCreator;

    //create a country.
    constructor(string memory name_, string memory description_, uint entryCost_, uint exitCost_) public {
        countryCreator = msg.sender;
        country.name = name_;
        country.description = description_;
        country.entryCost = entryCost_;
        country.exitCost = exitCost_;
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
        require(country.citizens[msg.sender].weight== 0||country.citizens[msg.sender].status ==0); // either not exist or normal exited
        country.treasury += country.entryCost; //update the treasury
        Citizen memory citizen = Citizen(msg.sender.balance - country.entryCost, 1, 1);
        country.citizens[msg.sender] = citizen; //TODO:check whether the citizen already exists
        return true;
    }
    
    //look up the index of a citizen in the citizen list.
    function isJoined(address citizenAddr) private view returns (bool) {
        return (country.citizens[msg.sender].weight!= 0 && (country.citizens[msg.sender].status ==1 || country.citizens[msg.sender].status == 2));
    }
    
    
    //leave the country. 
    function leave() public onlyCitizen payable returns (bool) {
        country.citizens[msg.sender].balance += msg.value; 
        require(country.citizens[msg.sender].balance >= country.exitCost, "Fail to pay the exit cost!");
        country.citizens[msg.sender].balance -= country.exitCost;
        country.treasury += country.exitCost;
        
        msg.sender.transfer(country.citizens[msg.sender].balance);
        country.citizens[msg.sender].status = 0;
        return true;
    }
    
    //leave the country. 
    function remove(address citizenAddr, uint nonce, bytes memory sig) public onlyCitizen payable returns (bool) {
        require(isApproved("remove",nonce,sig) == true);
        citizenAddr.send(country.citizens[citizenAddr].balance);
        country.citizens[citizenAddr].status = 99;
        return true;
    }
    
    
    //get balance based on a citizen address.
    function getCitizen(address citizenAddr) public view returns (uint256,uint8,uint256) {
        
        require(isJoined(citizenAddr)==true);
        return (country.citizens[msg.sender].balance, country.citizens[msg.sender].status,country.citizens[msg.sender].weight); 
    }
    
    //get the country name.
    function getName() public view returns (string memory) {
        return country.name;
    }
    
    //get the country description.
    function getDescription() public view returns (string memory) {
        return country.description;
    }
    
    //set the contry description. TODO: modifying name might involve voting.
    function setDescription(string memory description_,uint256 nonce, bytes memory sig) public {
        
        require(isApproved("setDescription",nonce,sig) == true);
        country.description = description_;
    }

    function getProgram() public view returns (address, string memory) {
        return (country.programAddr, country.programURL);
    }

    //set the mini program address.
    function setProgram(address programAddr_, string memory programURL_,uint256 nonce, bytes memory sig ) public {
        
        require(isApproved("setProgram",nonce,sig) == true);
        country.programAddr = programAddr_;
        country.programURL = programURL_;
    }
    
    function getCost() public view returns (uint, uint) {
        return (country.entryCost,country.exitCost);
    }
    
    //set the entry cost and the exit cost
    function setCost(uint entryCost_, uint exitCost_, uint256 nonce, bytes memory sig) public {
        
        require(isApproved("setCost",nonce,sig) == true);
        country.entryCost = entryCost_;
        country.exitCost = exitCost_;
    }

    //get the country treasury.
    function getTreasury() public onlyCountry view returns (uint) {
        return country.treasury;
    }

    function isApproved(string memory funcName, uint nonce, bytes memory sig) internal returns (bool)
    { 
        //require(!usedNonces[nonce]);
        usedNonces[nonce] = true;

        // This recreates the message that was signed on the client.
        bytes32 message = prefixed(keccak256(abi.encodePacked(address(this),funcName, nonce)));
        require(recoverSigner(message, sig) == admin);
        
        return true;
    }
    // Signature methods

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := and(mload(add(sig, 65)), 255)
         }
        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }
        
        return (v, r, s);
    }

   function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
   {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
