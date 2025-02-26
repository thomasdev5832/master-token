// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title MasterToken - An advanced ERC-20 token with extended functionality
/// @notice Implements ERC-20 with minting, burning, allowance adjustments, EIP-712 permit, and supply cap
/// @dev Uses Solidity 0.8.x built-in overflow protection and EIP-712 for off-chain approvals
contract MasterToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public maxSupply; // Limite máximo de tokens
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces; // Para EIP-712

    address public owner;
    bool public paused;

    // EIP-712 domain separator e constantes
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public DOMAIN_SEPARATOR;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    /// @notice Modifier to restrict functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice Modifier to restrict functions when contract is paused
    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }

    /// @notice Constructor to initialize the token with a max supply
    /// @param _name Name of the token
    /// @param _symbol Symbol of the token
    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = 18;
        maxSupply = 10000000 * 10**18; // Limite de 10M tokens
        _mint(msg.sender, 1000000 * 10**18); // 1M tokens iniciais

        // Inicializar EIP-712 Domain Separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice Mint new tokens to a specified address
    /// @param to Address to receive the minted tokens
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        require(to != address(0), "Invalid address");
        require(totalSupply + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }

    /// @notice Internal function to mint tokens
    /// @param to Address to receive the tokens
    /// @param amount Amount of tokens to mint
    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @notice Transfer tokens to a specified address
    /// @param to Recipient address
    /// @param amount Amount of tokens to transfer
    /// @return success Boolean indicating if the transfer was successful
    function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Approve a spender to transfer tokens on behalf of the caller
    /// @param spender Address allowed to spend tokens
    /// @param amount Amount of tokens approved
    /// @return success Boolean indicating if the approval was successful
    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        require(spender != address(0), "Invalid address");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Increase the allowance of a spender
    /// @param spender Address whose allowance will be increased
    /// @param addedValue Amount to increase the allowance by
    /// @return success Boolean indicating if the operation was successful
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        require(spender != address(0), "Invalid address");
        allowance[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    /// @notice Decrease the allowance of a spender
    /// @param spender Address whose allowance will be decreased
    /// @param subtractedValue Amount to decrease the allowance by
    /// @return success Boolean indicating if the operation was successful
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        require(spender != address(0), "Invalid address");
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Allowance underflow");
        allowance[msg.sender][spender] = currentAllowance - subtractedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    /// @notice Approve tokens via off-chain signature (EIP-712)
    /// @param permitOwner Address that signed the permit
    /// @param spender Address allowed to spend tokens
    /// @param value Amount of tokens approved
    /// @param deadline Expiration time of the signature
    /// @param v ECDSA signature parameter
    /// @param r ECDSA signature parameter
    /// @param s ECDSA signature parameter
    function permit(
        address permitOwner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public whenNotPaused {
        require(permitOwner != address(0), "Invalid owner");
        require(spender != address(0), "Invalid spender");
        require(block.timestamp <= deadline, "Permit expired");

        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, permitOwner, spender, value, nonces[permitOwner]++, deadline)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address recoveredAddress = ecrecover(digest, v, r, s);

        require(recoveredAddress != address(0) && recoveredAddress == permitOwner, "Invalid signature");
        allowance[permitOwner][spender] = value;
        emit Approval(permitOwner, spender, value);
    }

    /// @notice Transfer tokens from one address to another using allowance
    /// @param from Address to transfer tokens from
    /// @param to Address to transfer tokens to
    /// @param amount Amount of tokens to transfer
    /// @return success Boolean indicating if the transfer was successful
    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Burn tokens from the caller's balance
    /// @param amount Amount of tokens to burn
    function burn(uint256 amount) public whenNotPaused {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    /// @notice Burn tokens from another address using allowance
    /// @param from Address to burn tokens from
    /// @param amount Amount of tokens to burn
    function burnFrom(address from, uint256 amount) public whenNotPaused {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, address(0), amount);
    }

    /// @notice Transfer ownership of the contract to a new address
    /// @param newOwner Address of the new owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Pause the contract, disabling transfers and minting
    function pause() public onlyOwner {
        require(!paused, "Already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpause the contract, re-enabling transfers and minting
    function unpause() public onlyOwner {
        require(paused, "Not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }
}