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
        string indexed countryName,
        uint256 taxToBePaid
        );
    
    //define an event to disable the country.
    event DisableCountry(
        address indexed countryAddr,
        string indexed countryName
        );
    
    uint256 constant taxInterval = 10 seconds;
    uint256 constant maxWarningTime = 10 seconds;
    address payable admin = 0xb04b61254B42d64f17938E5DCe2eb728cAfF8937;
    mapping(uint256 => bool) usedNonces;
    Country country;
    address payable countryCreator;
    //address[] citizenList;
    mapping (address => uint256) balances;
    mapping (address => uint8) citizenStatus;//0->not in, 1->in, 2->left, 3->kicked out
    uint256 lastCheck;
    uint256 startWarning;
    bool isPaid;
    
    //create a country.
    constructor(string memory name_, string memory description_, uint256 entryCost_, uint256 tax_) public {
        countryCreator = msg.sender;
        country.name = name_;
        country.description = description_;
        country.entryCost = entryCost_;
        country.tax = tax_;
        setCitizenStatus(msg.sender, 1);
        lastCheck = now;
        isPaid = false;
        startWarning = 0;
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
        onCheck();
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
        onCheck();
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
    function kickOut(address citizenAddr) public returns (bool) {
        onCheck();
        require(getCitizenStatus(citizenAddr)==1, "The citizen is not in the group!");
        //penalty -- to be added???
        //if(balances[citizenAddr] < country.exitCost) {
        //    country.treasury += balances[citizenAddr];
        //    balances[citizenAddr] = 0;
        //} else {
        //    balances[citizenAddr] -= country.exitCost;
        //    country.treasury += country.exitCost;
        //}
        //remove from the citizen list (to be depredated)
        //bool isRemoved = removeCitizenFromList(citizenAddr);
        //set the citizen status to "kicked out"
        setCitizenStatus(citizenAddr, 3);
        return true;
    }
    
    //recharge the user's balance account.
    function recharge() public payable {
        onCheck();
        require(getCitizenStatus(msg.sender) == 1,"The citizen is not in the country yet!");
        balances[msg.sender] += msg.value;
    }
    
    //send money to pay the tax.
    function payTax() public payable {
        country.treasury += msg.value;
        deductTax();
    }
    
    //check the time interval to support the periodical tax payment from a country.
    function checkTaxInterval() private returns (bool) {
        if((now - lastCheck) >= taxInterval) {
            return true;
        } else {
            return false;
        }
    }
    
    //deduct the tax from the country treasury.
    function deductTax() private returns (bool) {
        if(country.treasury < country.tax) {
            if(isPaid) {
                //trigger a warning in the country
                emit TaxWarning(address(this), country.name, country.tax);
                //record the warning starting time
                startWarning = now;
            }
            isPaid = false;
        } else {//use the treasury to pay tax
            country.treasury -= country.tax;
            admin.transfer(country.tax);
            lastCheck = now;
            isPaid = true;
            startWarning = 0;
            return true;
        }
    }
    
    //check the duration of the warning. If it is over a maximal waiting time, disable the country.
    function checkWarningDuration() private {
        if((now-startWarning) > maxWarningTime && !isPaid) {
            //sent an event to disable everything
            emit DisableCountry(address(this), country.name);
        }
    }
    
    function onCheck() private {
        if(checkTaxInterval()) {
            deductTax();
        }
        if(startWarning != 0) {//if a warning is sent out.
            checkWarningDuration();
        }
    }
    
    //look up the index of a citizen in the citizen list (to be depredated).
    //function lookup(address citizenAddr) private view returns (uint) {
    //    uint i = 0;
    //    for(; i < citizenList.length; i++) {
    //        if(citizenList[i] == citizenAddr) return i;
    //    }
    //    require(i != citizenList.length, "Citizen is not found!");
    //}
    
    //add the citizen to the citizen list (to be depredated).
    //function addCitizenToList(address citizen_) private {
    //    citizenList.push(citizen_);
    //}
    
    //remove citizen from the citizen list (to be depredated).
    //function removeCitizenFromList(address citizenAddr) private returns (bool) {
    //    uint index = lookup(citizenAddr);
    //    if(index < citizenList.length) {
    //        citizenList[index] = citizenList[citizenList.length-1]; 
    //        citizenList.length--;
    //        //delete country.citizens[msg.sender];
    //        return true;
    //    } else {
    //        return false;
    //    }
    //}
    
    //get citizen status.
    function getCitizenStatus(address citizen_) public view returns (uint8) {
        return citizenStatus[citizen_];
    }
    
    //set citizen status.
    function setCitizenStatus(address citizen_, uint8 status_) public {
        onCheck();
        citizenStatus[citizen_] = status_;
    }
    
    //get citizen address list (to be depredated).
    //function getCitizenList() public view returns (address[] memory) {
    //    return citizenList;
    //}
    
    //get the address of the ith citizen from the citizen address list (to be depredated).
    //function getCitizen(uint8 i) public view returns (address) {
    //    return citizenList[i];
    //}
    
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
    
    //get the country description.
    function getDescription() public view returns (string memory) {
        return country.description;
    }
    
    //set the contry description. TODO: modifying name might involve voting.
    function setDescription(string memory description_,uint256 nonce, bytes memory sig) public onlyCountry {
        onCheck();
        require(isApproved("setDescription",nonce,sig) == true);
        country.description = description_;
    }
    
    //get the mini program address.
    // function getProgramAddr() public view returns (address) {
    //     return country.programAddr;
    // }
    
    // //set the mini program address.
    // function setProgramAddr(address programAddr_) public {
    //     country.programAddr = programAddr_;
    // }
    
    //get the mini program URL.
    // function getProgramURL() public view returns (string memory) {
    //     return country.programURL;
    // }
    
    // //set the mini program URL.
    // function setProgramURL(string memory programURL_) public {
    //     country.programURL = programURL_;
    // }

    function getProgram() public view returns (address, string memory) {
        return (country.programAddr, country.programURL);
    }

    //set the mini program address.
    function setProgram(address programAddr_, string memory programURL_,uint256 nonce, bytes memory sig ) public {
        onCheck();
        require(isApproved("setProgram",nonce,sig) == true);
        country.programAddr = programAddr_;
        country.programURL = programURL_;
    }
    
    //get the entry cost.
    // function getEntryCost() public view returns (uint) {
    //     return country.entryCost;
    // }
    
    // //set the entry cost.
    // function setEntryCost(uint cost_) public onlyCountry {
    //     country.entryCost = cost_;
    // }
    
    //get the exit cost.
    // function getExitCost() public view returns (uint) {
    //     return country.exitCost;
    // }
    
    // //set the exit cost.
    // function setExitCost(uint cost_) public onlyCountry {
    //     country.exitCost = cost_;
    // }
    
    function getCost() public view returns (uint256, uint256) {
        return (country.entryCost,country.tax);
    }
    
    //set the entry cost and the tax
    function setCost(uint256 entryCost_, uint256 tax_, uint256 nonce, bytes memory sig) public onlyCountry {
        onCheck();
        require(isApproved("setCost",nonce,sig) == true);
        country.entryCost = entryCost_;
        country.tax = tax_;
    }
    
    //set the entry cost and the tax
    function setCost(uint256 entryCost_, uint256 tax_) public onlyCountry {
        onCheck();
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
