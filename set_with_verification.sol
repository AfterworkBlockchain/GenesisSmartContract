pragma solidity ^0.5.00;

contract SetWithVerification {
    address admin = 0xb04b61254B42d64f17938E5DCe2eb728cAfF8937;
    uint entryCost = 0;

    mapping(uint256 => bool) usedNonces;

    function setEntryCost(uint256 cost, uint256 nonce, bytes memory sig) public 
    {
        require(isApproved("setEntryCost",nonce,sig) == true);
        entryCost = cost;
    }

    // Destroy contract and reclaim leftover funds.
    function kill() public 
    {
        require(msg.sender == admin);
        selfdestruct(msg.sender);
    }

   function isApproved(string memory funcName, uint nonce, bytes memory sig) internal pure returns (bool)
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
