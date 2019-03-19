pragma solidity >=0.5.0;

contract GenesisSpace{
    //define a genesis country.
    struct Country {
        string name; 
        string description; 
        address programAddr; //address for mini programs
        string programURL; //URL for mini programs
        uint256 treasury;
        uint256 entryCost;
        uint256 tax;
    }
    
    //define a warning for the tax to be paid.
    event TaxWarning(
        address indexed countryAddr,
        string indexed countryName      
        );
    
    //define an event to disable the country.
    event DisableCountry(
        address indexed countryAddr,
        string indexed countryName
        );
    
    uint256 constant taxInterval = 86400 seconds;

    address payable admin = 0xb04b61254B42d64f17938E5DCe2eb728cAfF8937;
    uint8 warningLimit = 3
    mapping(uint256 => bool) usedNonces;
    Country country;
    address countryCreator;
    mapping (address => uint256) balances;
    mapping (address => uint8) citizenStatus;//0->not in, 1->in, 2->left, 3->kicked out
    uint256 lastCheck;
    bool isEnabled;
    
    //create a country.
    constructor(string memory name_, string memory description_, uint256 entryCost_, uint256 tax_) payable public {
        countryCreator = msg.sender;
        country.name = name_;
        country.description = description_;
        country.entryCost = entryCost_;
        country.tax = tax_;
        setCitizenStatus(msg.sender, 1);
        lastCheck = now;
        isEnabled = true;
        country.treasury += msg.value;
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

    modifier CountryEnabled() {
        require(
            isEnabled == true,
            "Country is disabled due to not paying tax."
        );
        _;
    }
    
    //join the country. It can be only called by citizens.
    function join() public onlyCitizen payable returns (bool) {
        require(msg.value >= country.entryCost, "Failed to pay the entry cost!");
        //require(getCitizenStatus(msg.sender) == 1, "The citizen is already in the country!");
        country.treasury += country.entryCost; //update the treasury
        balances[msg.sender] = msg.value - country.entryCost;
        //addCitizenToList(msg.sender); //add the citizen address to the citizen list
        setCitizenStatus(msg.sender, 1); //set the "in" status for the citizen
        return true;
    }
    
     //leave the country. 
    function leave() public onlyCitizen returns (bool) {
        require(getCitizenStatus(msg.sender)==1, "The citizen was never in the group!");
        //send the user balance back to the citizen
        msg.sender.transfer(balances[msg.sender]);
        //set the balance to 0
        balances[msg.sender] = 0;
        //set the citizen status to "left"
        setCitizenStatus(msg.sender, 2);
        return true;
    }
    
    //The admin kicks the citizen out.
    function kickOut(address payable citizenAddr,uint256 nonce, bytes memory sig) CountryEnabled public payable returns (bool) {
        require(getCitizenStatus(citizenAddr)==1, "The citizen is not in the group!");
        require(isApproved("kickOut",nonce,sig) == true);
        setCitizenStatus(citizenAddr, 3);
        citizenAddr.transfer(balances[citizenAddr]);
        return true;
    }
    
    //recharge the user's balance account.
    function recharge() public payable {
        require(getCitizenStatus(msg.sender) == 1,"The citizen is not in the country yet!");
        balances[msg.sender] += msg.value;
    }
    
    //TODO: withdraw
    function withdraw(uint256 value) public payable {
        require(getCitizenStatus(msg.sender) == 1,"The citizen is not in the country yet!");
        require(value <= balances[msg.sender]);
        balances[msg.sender] -= value;
        msg.sender.transfer(value);
    }
    //send money to pay the tax.
    function payTax() public payable {
        country.treasury += msg.value;
    }
    
    //check the time interval to support the periodical tax payment from a country.
    function checkTaxInterval() private view returns (bool) {
        if((now - lastCheck) >= taxInterval) {
            return true;
        } else {
            return false;
        }
    }
    
    //deduct the tax from the country treasury.

    function deductTax() private {
        if(country.treasury < country.tax) {
            emit DisableCountry(address(this), country.name);
            isEnabled == false;
        } else {//use the treasury to pay tax
            country.treasury -= country.tax;
            admin.transfer(country.tax);
            lastCheck = now;
            isEnabled = true;
        }
    }
    
    function onCheck() private {
        require(checkTaxInterval()==true);
        if(country.treasury < warningLimit * country.tax && country.treasury >= country.tax){
            emit TaxWarning(address(this), country.name);
        }
        deductTax();
    }
    
    function onExTrigger() public{
        require(msg.sender == admin, "This function is only allowed to be executed from admin");
        onCheck();
    }

    //get citizen status.
    function getCitizenStatus(address citizen_) public view returns (uint8) {
        return citizenStatus[citizen_];
    }
    
    //set citizen status.
    function setCitizenStatus(address citizen_, uint8 status_) private {
        citizenStatus[citizen_] = status_;
    }
    
    //get balance based on a citizen address.
    function getBalance(address addr) public view returns (uint) {
        return balances[addr];
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
    function setDescription(string memory description_,uint256 nonce, bytes memory sig) public CountryEnabled {
        require(isApproved("setDescription",nonce,sig) == true);
        country.description = description_;
    }

    function getProgram() public view returns (address, string memory) {
        return (country.programAddr, country.programURL);
    }

    //set the mini program address.
    function setProgram(address programAddr_, string memory programURL_, uint256 nonce, bytes memory sig ) CountryEnabled public {
        require(isApproved("setProgram",nonce,sig) == true);
        country.programAddr = programAddr_;
        country.programURL = programURL_;
    }

    function getCost() public view returns (uint256, uint256) {
        return (country.entryCost,country.tax);
    }
    
    //set the entry cost and the tax
    function setCost(uint256 entryCost_, uint256 tax_, uint256 nonce, bytes memory sig) public CountryEnabled {
        require(isApproved("setCost",nonce,sig) == true);
        country.entryCost = entryCost_;
        country.tax = tax_;
    }
    
    //get the country treasury.
    function getTreasury() public view returns (uint256) {
        return country.treasury;
    }

    function isApproved(string memory funcName, uint nonce, bytes memory sig) internal returns (bool)
    { 
        require(!usedNonces[nonce]);
        usedNonces[nonce] = true;

        // This recreates the message that was signed on the client.
        bytes32 message = prefixed(keccak256(abi.encodePacked(this, funcName, nonce)));
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
            v := byte(0, mload(add(sig, 96)))
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