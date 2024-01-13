// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract TokenSale is ERC20, Ownable {

    // token info
    uint256 constant public tokenPrice = 0.1 ether;
    string private tokenName = "ProjectToken";
    string private tokenSymbol = "PT";

    // Variables for presale and public sale parameters
    uint256 private presaleCap;
    uint256 private presaleMinConstribution;
    uint256 private presaleMaxConstribution;
    uint256 private publicSalecap;
    uint256 private publicSaleMinconstribution;
    uint256 private publicSaleMaxConstribution;

    // Variables to track total contributions and contributors
    uint256 public totalPresaleConstributor = 0;
    uint256 public totalPresaleConstribution = 0;
    uint256 public totalPublicSaleConstributor = 0;
    uint256 public totalPublicSaleConstribution = 0;

    // Mapping to track individual contributions during presale and public sale
    mapping(address => uint256) public presaleConstributor;
    mapping(address => uint256) public publicSaleConstributor;

    // Flags to track the status of presale and public sale
    bool public presaleEnded = false;
    bool public publicSaleStarted = false;
    bool public publicSaleEnded = false;

    // Event to log token purchases
    event TokensPurchased(address indexed buyer, uint256 amount, bool isPresale);

    // Modifiers to enforce certain conditions
    modifier onlyBeforePublicSale() {
        require(!publicSaleStarted && !presaleEnded, "Presale has Ended");
        _;
    }

    modifier onlyAfterPreSale() {
        require(presaleEnded, "Presale running");
        _;
    }

    modifier onlyBeforePublicSaleEnd() {
        require(!publicSaleEnded, "Public sale has Ended");
        _;
    }

    modifier onlyAfterPublicSaleEnd() {
        require(publicSaleEnded && presaleEnded, "Public sale is running");
        _;
    }

    // Constructor to initialize parameters
    constructor(
        uint256 _presaleCap,
        uint256 _presaleMinConstribution,
        uint256 _presaleMaxConstribution,
        uint256 _publicSaleCap,
        uint256 _publicSaleMinConstribution,
        uint256 _publicSaleMaxConstribution
    )
        ERC20(tokenName, tokenSymbol)
        Ownable(msg.sender)
    {
        presaleCap = _presaleCap;
        presaleMinConstribution = _presaleMinConstribution;
        presaleMaxConstribution = _presaleMaxConstribution;
        publicSalecap = _publicSaleCap;
        publicSaleMinconstribution = _publicSaleMinConstribution;
        publicSaleMaxConstribution = _publicSaleMaxConstribution;
    }

    // Fallback and receive functions to reject incoming Ether
    fallback() external {}

    receive() external payable {
        revert();
    }

    // Presale function where contributors can participate
    function presale() payable external onlyBeforePublicSale {
        uint256 _amount = msg.value;
        require(_amount >= presaleMinConstribution, "Minimum contribution not fulfilled");

        uint256 totalContribution = presaleConstributor[msg.sender] + _amount;
        require(totalContribution <= presaleMaxConstribution, "Exceeds Presale Maximum contribution");

        uint256 totalPresaleEther = totalPresaleConstribution + _amount;
        require(totalPresaleEther <= presaleCap, "Exceeds Presale cap");

        totalPresaleConstribution += _amount;
        totalPresaleConstributor++;

        presaleConstributor[msg.sender] += _amount;

        mintToken(msg.sender, _amount);
        emit TokensPurchased(msg.sender, _amount, true);
    }

    // Function to increase the presale cap, only callable by the owner
    function increasePresaleCap(uint256 _amount) external onlyOwner onlyBeforePublicSale {
        presaleCap += _amount;
    }

    // Public sale function where contributors can participate
    function publicSale() payable external onlyAfterPreSale onlyBeforePublicSaleEnd {
        require(publicSaleStarted, "Public sale has not started yet");
        uint256 _amount = msg.value;
        require(_amount > publicSaleMinconstribution, "Minimum criteria do not match");

        uint256 totalContribution = publicSaleConstributor[msg.sender] + _amount;
        require(totalContribution <= publicSaleMaxConstribution, "Maximum contribution has been reached");

        uint256 totalPublicSaleCap = totalPublicSaleConstribution + _amount;
        require(totalPublicSaleCap <= publicSalecap, "Exceed public sale cap");

        totalPublicSaleConstribution += _amount;
        totalPublicSaleConstributor++;

        publicSaleConstributor[msg.sender] += _amount;

        mintToken(msg.sender, _amount);
        emit TokensPurchased(msg.sender, _amount, false);
    }

    // Function to increase the public sale cap, only callable by the owner
    function increasePublicSaleCap(uint256 _amount) external onlyOwner onlyBeforePublicSaleEnd {
        publicSalecap += _amount;
    }

    // Function to distribute tokens to a specific address, only callable by the owner
    function distributeToken(address _address, uint256 _value) external onlyOwner {
        _mint(_address, _value);
    }

    // Function to process refunds, only callable after the public sale ends
    function refund() external onlyAfterPublicSaleEnd {
        require(address(this).balance > 0, "Refund not available");
        uint256 amount = presaleConstributor[msg.sender] + publicSaleConstributor[msg.sender];
        require(amount > 0, "You don't have enough funds");

        presaleConstributor[msg.sender] = 0;
        publicSaleConstributor[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    // Function to end the presale, only callable by the owner
    function endPreSale() public onlyOwner onlyBeforePublicSale {
        presaleEnded = true;
    }

    // Function to start the public sale, only callable by the owner
    function startPublicSale() public onlyOwner onlyAfterPreSale {
        publicSaleStarted = true;
    }

    // Function to end the public sale, only callable by the owner
    function endPublicSale() public onlyOwner onlyAfterPreSale {
        publicSaleEnded = true;
    }

    // View function to get the presale cap
    function getPreSaleCap() public view returns (uint256) {
        return presaleCap;
    }

    // View function to get the public sale cap
    function getPublicSaleCap() public view returns (uint256) {
        return publicSalecap;
    }

    // View functions to get presale contribution details
    function getPresaleMinConstributionDetails() public view returns (uint256) {
        return presaleMinConstribution;
    }

    function getPresaleMaxConstributionDetails() public view returns (uint256) {
        return presaleMaxConstribution;
    }

    // View functions to get public sale contribution details
    function getPublicSaleMinConstributionDetails() public view returns (uint256) {
        return publicSaleMinconstribution;
    }

    function getPublicSaleMaxConstributionDetails() public view returns (uint256) {
        return publicSaleMaxConstribution;
    }

    // Private function to mint tokens, only callable by the contract
    function mintToken(address _to, uint256 _amount) private {
        uint256 value = _amount / tokenPrice; 
        // lets say amount = 400000000000000000
        // value = 400000000000000000 / 100000000000000000
        //     = 4 
        _mint(_to, value * 10 ** decimals());
    }
}