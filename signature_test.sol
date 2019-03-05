pragma solidity >=0.4.0;

contract TestSha3{
    uint256 nonce = 1;
    string funcName = 'setCost';
    address contractAddr = 0xf4B256427DEd7eaE62040b13684ba7487c0a1825;
    address admin = 0xb04b61254B42d64f17938E5DCe2eb728cAfF8937;

    bytes32 msg1Hash;
    bytes32 msg2Hash;
    
    
    // This is the signature calculated from golang lib, based on the same parameter as above.
    bytes signature = hex"8b0e29eb7518fbb3e0391b73d9bd17d28cba715674ffb8fdc79537fd6406673f3b625f8d52c5e9556de3fb8e10ad9184c7c05ceb1de6d700a26b48446882c43c00";
    

    function step1_1sthash() public returns (bytes32){
         msg1Hash = keccak256(abi.encodePacked(contractAddr, funcName, nonce));
         return msg1Hash;
    }
    
    function step2_2ndhash() public returns (bytes32) {
        msg2Hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msg1Hash));
        return msg2Hash;}
    
    function step3_verify()public returns (address){
        
        address recov = recoverSigner(msg2Hash, signature);
        require(recov == admin);
        return recov;
    }
    
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
    
}