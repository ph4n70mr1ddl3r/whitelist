// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MerkleAirdropVerifier.sol";

/// @title MerkleAirdropToken
/// @notice Simple ERC20 with a one-time mint of 100 tokens per whitelisted address verified by Merkle proof.
contract MerkleAirdropToken is MerkleAirdropVerifier {
    string public constant name = "Merkle Airdrop Token";
    string public constant symbol = "MAT";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    uint256 public constant AIRDROP_AMOUNT = 100 * 10 ** 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public claimed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AirdropClaimed(address indexed account, uint256 amount);

    error AlreadyClaimed();
    error InsufficientBalance();
    error InsufficientAllowance();

    /// @notice Claim the airdrop. Caller must be in the Merkle whitelist and can claim only once.
    /// @param proof Sibling hashes from leaf to root.
    /// @param siblingLeft For each proof element, true if the sibling is on the left of the current hash.
    function claim(bytes32[] calldata proof, bool[] calldata siblingLeft) external returns (bool) {
        if (claimed[msg.sender]) revert AlreadyClaimed();
        bool valid = verifyProof(leafOf(msg.sender), proof, siblingLeft, MERKLE_ROOT);
        if (!valid) revert InvalidProof();

        claimed[msg.sender] = true;
        _mint(msg.sender, AIRDROP_AMOUNT);
        emit AirdropClaimed(msg.sender, AIRDROP_AMOUNT);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (_balances[from] < amount) revert InsufficientBalance();
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance < amount) revert InsufficientAllowance();
        unchecked {
            _allowances[owner][spender] = currentAllowance - amount;
        }
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}
