// SPDX-License-Indetifier: MIT

pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TokenSale is ERC20, Ownable {

    uint256 private presaleCap;
    uint256 private presaleMinConstribution;
    uint256 private presaleMaxConstribution;
    uint256 private publicSalecap;
    uint256 private publicSaleMinconstribution;
    uint256 private publicSaleMaxConstribution;


    uint256 public totalPresaleConstributor = 0;
    uint256 public totalPresaleConstribution = 0;
    uint256 public totalPublicSaleConstributor = 0;
    uint256 public totalPublicSaleConstribution = 0;

    mapping(address => uint256) public presaleConstributor;
    mapping(address => uint256) public publicSaleConstributor; 
    
    bool public presaleEnded = false;
    bool public publicSaleStarted = false;
    bool public publicSaleEnded = false;

    modifier onlyBeforePublicSale() {
        require(!publicSaleStarted && !presaleEnded, "Presale has Ended");
        _;
    }

    modifier onlyAfterPreSale() {
        require(presaleEnded, "Presale running" );
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
 
    event TokensPurchased(address indexed buyer, uint256 amount, bool isPresale);

    constructor(
        uint256 _presaleCap,
        uint256 _presaleMinConstribution,
        uint256 _presaleMaxConstribution,
        uint256 _publicSaleCap,
        uint256 _publicSaleMinConstribution,
        uint256 _publicSaleMaxConstribution
    )
        ERC20("ProjectToken", "PT")
        Ownable(msg.sender)
    {
        presaleCap = _presaleCap;
        presaleMinConstribution = _presaleMinConstribution;
        presaleMaxConstribution = _presaleMaxConstribution;
        publicSalecap = _publicSaleCap;
        publicSaleMinconstribution = _publicSaleMinConstribution;
        publicSaleMaxConstribution = _publicSaleMaxConstribution;
    }

    function mintToken(address _to, uint256 _value) private {
        _mint(_to, _value);
    }

    function presale() payable external onlyBeforePublicSale {
        uint256 _amount = msg.value;
        require(_amount >= presaleMinConstribution, "Minimum constribution doesnt fullfiled");

        uint256 totalConstribution = presaleConstributor[msg.sender] + _amount;
        require(totalConstribution <= presaleMaxConstribution, "Exceeds Presale Maximum constribution");
        
        uint256 totalpresaleEther = totalPresaleConstribution + _amount;
        require(totalpresaleEther <= presaleCap, "Exceeds Presale cap");

        totalPresaleConstribution += _amount;
        totalPresaleConstributor++;
        
        presaleConstributor[msg.sender] += _amount;
        
        mintToken(msg.sender, _amount);
        emit TokensPurchased(msg.sender, _amount, true);
    }

    function increasePresaleCap(uint256 _amount) external onlyOwner onlyBeforePublicSale{
        presaleCap += _amount;
    }

    function publicSale() payable external onlyAfterPreSale onlyBeforePublicSaleEnd {
        require(publicSaleStarted, "Public sale hasnt been satrted yet");
        uint256 _amount = msg.value;
        require(_amount > publicSaleMinconstribution, "Minimum criteria doesnt match" );

        uint256 totalConstribution = publicSaleConstributor[msg.sender] + _amount;
        require(totalConstribution <= publicSaleMaxConstribution, "Maximum constribution has been reached");

        uint256 totalPublicSaleCap = totalPublicSaleConstribution + _amount;
        require(totalPublicSaleCap <= publicSalecap, "Exceed public sale cap");

        totalPublicSaleConstribution += _amount;
        totalPublicSaleConstributor++;

        publicSaleConstributor[msg.sender] += _amount;

        mintToken(msg.sender, _amount);
        emit TokensPurchased(msg.sender, _amount, false);
    }

    function increasePublicSaleCap(uint256 _amount) external onlyOwner onlyBeforePublicSaleEnd {
        publicSalecap += _amount;
    }

    function distributeToken(address _address, uint256 _value) external onlyOwner {
        _mint(_address, _value);
    }

    function refund() external onlyAfterPublicSaleEnd{
        require(address(this).balance > 0, "Refund not available");
        uint256 amount = presaleConstributor[msg.sender] + publicSaleConstributor[msg.sender];
        require(amount > 0, "You dont have enough funds");

        presaleConstributor[msg.sender] = 0;
        publicSaleConstributor[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    function endPreSale() public onlyOwner onlyBeforePublicSale {
        presaleEnded = true;
    }

    function startPublicSale() public onlyOwner onlyAfterPreSale {
        publicSaleStarted = true;
    }

    function endPublicSale() public onlyOwner onlyAfterPreSale { 
        publicSaleEnded = true;
    }

    function getPreSaleCap() public view returns(uint256){
        return presaleCap;
    }

    function getPublicSaleCap() public view returns(uint256){
        return publicSalecap;
    }

    function getPresaleMinConstributionDetails() public view returns(uint256) {
        return presaleMinConstribution;
    }

    function getPresaleMaxConstributionDetails() public view returns(uint256) {
        return presaleMaxConstribution;
    }

    function getpublicSaleMinConstributionDetails() public view returns(uint256) {
        return publicSaleMinconstribution;
    }

    function getpublicSaleMaxConstributionDetails() public view returns(uint256) {
        return publicSaleMaxConstribution;
    }

    fallback() external {

    }

    receive() external payable {
        revert();
    }
}