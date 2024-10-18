// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ECCVerification {

    struct G1Point {
        uint X;
        uint Y;
    }

    enum stage {created, initialized, accepted, keyRevealed}
    stage public phase = stage.created;

    address sender;
    address receiver;
    uint public price; // in wei
    uint public timeout;

    bytes32 public EnA_b; // buyer's private key encrypt by public key fron seller
    G1Point public B; // public key from buyer

    uint256[] public commitment;

    event KeyRevealed(address indexed receiver, G1Point[] En_key);
    //G1Point[] public En_key;

    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    // go to next phase
    function nextStage() internal {
        phase = stage(uint(phase) + 1);
        timeout = block.timestamp + 10 minutes;
    }

    // function modifier to only allow calling the function in the right phase only from the correct party
    modifier allowed(address p, stage s) {
        require(phase == s);
        require(block.timestamp < timeout);
        require(msg.sender == p);
        _;
    }

    // constructor is initialize function
    function ininitialize (address _receiver, uint _price) public {

        require(phase == stage.created);
        receiver = _receiver;
        sender = msg.sender;
        price = _price * 1000000000000000000;

        nextStage();
    }

    // function accept
    function accept (bytes32 _EnA_b, G1Point memory _B, uint256[] memory _commitment) allowed(receiver, stage.initialized) payable public {

        require (msg.value >= price);

        EnA_b = _EnA_b;
        B = _B;
        commitment = _commitment;

        nextStage();
    }

    // function revealKey (_En_key) = k+b
    function revealKey (G1Point[] memory _En_key) allowed(sender, stage.accepted) public {

        //require(keyCommit == keccak256(_key));
        //require(keyCommit == keccak256(abi.encodePacked(_key)), "Invalid key commitment");

        require(verifyBatch(_En_key, B, commitment) == true, "verify fail");

        //En_key = _En_key;
        emit KeyRevealed(receiver, _En_key);

        (payable(sender)).transfer(price);

        phase = stage.created;
    }

    // refund function is called in case some party did not contribute in time
    function refund () public {
        require (block.timestamp > timeout);
        if (phase == stage.accepted) {
            (payable(receiver)).transfer(price);
            phase = stage.created;
        }
        else if (phase >= stage.keyRevealed) {
            (payable(receiver)).transfer(price);
            phase = stage.created;
        }
    }

    /// @dev Performs addition of two G1 points.
    /// @param p1 The first G1 point.
    /// @param p2 The second G1 point.
    /// @return result The resulting point after addition.
    function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory result) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;

        uint[2] memory output;  // 用於存儲結果

        bool success;
        assembly {
            // 調用地址 0x06 上的預編譯合約進行 G1 點加法運算
            success := staticcall(not(0), 0x06, input, 0x80, output, 0x40)
        }
        require(success, "BN256: point addition failed");

        return G1Point(output[0], output[1]);
    }

    /// @dev Performs scalar multiplication of a G1 point and a scalar.
    /// @param p The G1 point.
    /// @param s The scalar.
    /// @return r The resulting point after multiplication.
    function scalarMul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;

        // Prepare an output array for the result
        uint[2] memory output;

        bool success;
        assembly {
            success := staticcall(not(0), 0x07, input, 0x60, output, 0x40)
        }
        require(success, "BN256: scalar multiplication failed");

        return G1Point(output[0], output[1]);
    }

    function verifyBatch(
        G1Point[] memory MArray, 
        G1Point memory publicKeyFromBuyer, 
        uint256[] memory cArray
    ) public view returns (bool) {
        // 檢查陣列長度是否一致
        require(MArray.length == cArray.length, "Input arrays must have the same length");

        for (uint256 i = 0; i < MArray.length; i++) {
            // 計算 M + B
            G1Point memory MplusB = add(MArray[i], publicKeyFromBuyer);

            // 計算 C = c * G
            G1Point memory C = scalarMul(P1(), cArray[i]);

            // 如果有任何一次驗證失敗，直接返回 false
            if (C.X != MplusB.X || C.Y != MplusB.Y) {
                return false;
            }
        }
        return true;
    }
}